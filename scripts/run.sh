#!/bin/bash
#
# Prepare our container for initial boot.

# Where does our MySQL data live?
VOLUME_HOME="/var/lib/mysql"

#######################################
# Use sed to replace apache php.ini values for a given PHP version.
# Globals:
#   PHP_UPLOAD_MAX_FILESIZE
#   PHP_POST_MAX_SIZE
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 5.6, 7.3 etc.
# Returns:
#   None
#######################################
function replace_apache_php_ini_values () {
    echo "Updating for PHP $1"

    sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
        -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php/$1/apache2/php.ini

    sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/$1/apache2/php.ini

}
if [ -e /etc/php/5.6/apache2/php.ini ]; then replace_apache_php_ini_values "5.6"; fi
if [ -e /etc/php/$PHP_VERSION/apache2/php.ini ]; then replace_apache_php_ini_values $PHP_VERSION; fi

#######################################
# Use sed to replace cli php.ini values for a given PHP version.
# Globals:
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 5.6, 7.3 etc.
# Returns:
#   None
#######################################
function replace_cli_php_ini_values () {
    echo "Replacing CLI php.ini values"
    sed -i  "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/$1/cli/php.ini
}
if [ -e /etc/php/5.6/cli/php.ini ]; then replace_cli_php_ini_values "5.6"; fi
if [ -e /etc/php/$PHP_VERSION/cli/php.ini ]; then replace_cli_php_ini_values $PHP_VERSION; fi

echo "Editing APACHE_RUN_GROUP environment variable"
sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

if [ -n "$APACHE_ROOT" ];then
    echo "Linking /var/www/html to the Apache root"
    rm -f /var/www/html && ln -s "/app/${APACHE_ROOT}" /var/www/html
fi

echo "Editing phpmyadmin config"
sed -i "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`date | md5sum`'/" /var/www/phpmyadmin/config.inc.php

echo "Setting up MySQL directories"
mkdir -p /var/run/mysqld

# Setup user and permissions for MySQL and Apache
chmod -R 770 /var/lib/mysql
chmod -R 770 /var/run/mysqld

if [ -n "$VAGRANT_OSX_MODE" ];then
    echo "Setting up users and groups"
    usermod -u $DOCKER_USER_ID www-data
    groupmod -g $(($DOCKER_USER_GID + 10000)) $(getent group $DOCKER_USER_GID | cut -d: -f1)
    groupmod -g ${DOCKER_USER_GID} staff
else
    echo "Allowing Apache/PHP to write to the app"
    # Tweaks to give Apache/PHP write permissions to the app
    chown -R www-data:staff /var/www
    chown -R www-data:staff /app
fi

echo "Allowing Apache/PHP to write to MySQL"
chown -R www-data:staff /var/lib/mysql
chown -R www-data:staff /var/run/mysqld
chown -R www-data:staff /var/log/mysql

# Listen only on IPv4 addresses
sed -i 's/^Listen .*/Listen 0.0.0.0:80/' /etc/apache2/ports.conf

if [ -e /var/run/mysqld/mysqld.sock ];then
    echo "Removing MySQL socket"
    rm /var/run/mysqld/mysqld.sock
fi

echo "Editing MySQL config"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/user.*/user = www-data/" /etc/mysql/mysql.conf.d/mysqld.cnf

INIT=false

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    INIT=true
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."

    # Try the 'preferred' solution
    mysqld --initialize-insecure --innodb-flush-log-at-trx-commit=0 --skip-log-bin

    # IF that didn't work
    if [ $? -ne 0 ]; then
        # Fall back to the 'depreciated' solution
        mysql_install_db > /dev/null 2>&1
    fi

    echo "=> Done!"
    /create_mysql_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi

echo "Starting sshd"
service ssh start
ssh-keyscan -t rsa localhost >> ~/.ssh/known_hosts
ssh-keyscan -t rsa 127.0.0.1 >> ~/.ssh/known_hosts
ssh-keyscan -t ecdsa localhost >> ~/.ssh/known_hosts
ssh-keyscan -t ecdsa 127.0.0.1 >> ~/.ssh/known_hosts

echo "Starting Hadoop"
cd /home/hadoop/hadoop-current
if [[ $INIT ]] ; then
    echo "formatting namenode..."
    echo "Y" | bin/hadoop namenode -format
fi
bin/start-dfs.sh
bin/start-mapred.sh

if [[ $INIT ]] ; then
    echo "installing live dataset..."
    cd /home/hadoop
    hadoop-current/bin/hadoop dfs -mkdir /repcache
    hadoop-current/bin/hadoop dfs -mkdir /repcache/live
    hadoop-current/bin/hadoop dfs -mkdir /repcache/live/ast
    hadoop-current/bin/hadoop dfs -put /home/hadoop/live-dataset/projects.seq /repcache/live/projects.seq
    hadoop-current/bin/hadoop dfs -put /home/hadoop/live-dataset/ast/index /repcache/live/ast/index
    hadoop-current/bin/hadoop dfs -put /home/hadoop/live-dataset/ast/data /repcache/live/ast/data
fi

cd /home/hadoop/bin
./run-poller.sh >/dev/null 2>&1 &

tail -n+2 /etc/hosts > hosts2
echo "127.0.0.1	localhost head" >> hosts2
cat hosts2 > /etc/hosts
rm -f hosts2

echo "===========> Boa Information <=========="
echo "       URL: http://localhost:$WWW_PUBLISHED_PORT/boa/"
echo "      user: boa"
echo "  password: rocks"
echo "===========> Boa Information <=========="

echo "Starting supervisord"
exec supervisord -n