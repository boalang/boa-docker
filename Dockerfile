FROM mattrayner/lamp:latest-2004

RUN apt-get update && apt-get install git php-xml zip
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && ln -s /usr/local/bin/composer /usr/bin/composer
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush \
    && cd /usr/local/src/drush \
    && git checkout 8.4.10 \
    && ln -s /usr/local/src/drush/drush /usr/bin/drush \
    && composer install

# install JDK
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes openjdk-11-jdk

# install Drupal
RUN cd /app; drush dl drupal-7 ; mv drupal-7.* boa
RUN cd /app/boa/sites/all/modules ; git clone https://github.com/boalang/drupal.git boa

# fix some settings for Drupal
ADD conf/apache2.conf /etc/apache2/apache2.conf
RUN cd /app/boa/sites/default ; cp default.settings.php settings.php ; chmod 666 settings.php ; chown www-data:staff settings.php ; mkdir files ; chmod 777 files ; chown www-data:staff files

# install Hadoop 1.2.1
RUN groupadd hadoop
RUN useradd -g hadoop -ms /bin/bash hadoop

ADD https://archive.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz /home/hadoop/hadoop-1.2.1-bin.tar.gz
RUN cd /home/hadoop ; tar xzf hadoop-1.2.1-bin.tar.gz ; ln -s hadoop-1.2.1 hadoop-current

RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop-current/conf" >> /etc/apache2/envvars

ADD https://search.maven.org/remotecontent?filepath=com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar /home/hadoop/hadoop-current/lib/protobuf-java-2.5.0.jar
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes libsnappy-dev libmariadb-java
RUN cp /usr/lib/x86_64-linux-gnu/libsnappy.* /home/hadoop/hadoop-current/lib/native/Linux-amd64-64
RUN ln -s /usr/share/java/mariadb-java-client.jar /home/hadoop/hadoop-current/lib/mariadb-java-client.jar

RUN mkdir /data ; chown hadoop:hadoop /data
ADD conf/hadoop-env.sh /home/hadoop/hadoop-current/conf/hadoop-env.sh
ADD conf/core-site.xml /home/hadoop/hadoop-current/conf/core-site.xml
ADD conf/hdfs-site.xml /home/hadoop/hadoop-current/conf/hdfs-site.xml
ADD conf/mapred-site.xml /home/hadoop/hadoop-current/conf/mapred-site.xml

# setup sshd
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes libsnappy-dev openssh-server
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# add Boa backend scripts
ADD https://boa.cs.iastate.edu/cloudlab/BoaCompilePoller.java /home/hadoop/bin/BoaCompilePoller.java
ADD https://boa.cs.iastate.edu/cloudlab/run-poller.sh /home/hadoop/bin/run-poller.sh
ADD https://boa.cs.iastate.edu/cloudlab/boa-compile.sh /home/hadoop/bin/boa-compile.sh
ADD https://boa.cs.iastate.edu/cloudlab/boa-run.sh /home/hadoop/bin/boa-run.sh
RUN chmod 755 /home/hadoop/bin/*.sh ; chown hadoop:hadoop -R /home/hadoop/bin

# add Boa sample dataset
ADD https://boa.cs.iastate.edu/cloudlab/index /home/hadoop/live-dataset/ast/index
ADD https://boa.cs.iastate.edu/cloudlab/data /home/hadoop/live-dataset/ast/data
ADD https://boa.cs.iastate.edu/cloudlab/projects.seq /home/hadoop/live-dataset/projects.seq
RUN chown hadoop:hadoop -R /home/hadoop/live-dataset/

# add Boa compiler/runtime (needs to match the dataset)
ADD https://boa.cs.iastate.edu/cloudlab/boa-compiler.jar /home/hadoop/compiler/live/dist/boa-compiler.jar
ADD https://boa.cs.iastate.edu/cloudlab/boa-runtime.jar /home/hadoop/compiler/live/dist/boa-runtime.jar
RUN chown hadoop:hadoop -R /home/hadoop/compiler

# install Ace syntax highlighter
#RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes npm
#RUN cd /tmp ; git clone https://github.com/boalang/ace.git
#RUN cd /tmp/ace ; npm install --no-audit ; nodejs /tmp/ace/Makefile.dryice.js full --target /app/boa/sites/all/libraries/ace
ADD https://boa.cs.iastate.edu/cloudlab/ace.tgz /app/boa/sites/all/libraries/ace.tgz
RUN cd /app/boa/sites/all/libraries ; tar xzf ace.tgz

# replace scripts with custom versions
ADD scripts/run.sh /run.sh
ADD scripts/create_mysql_users.sh /create_mysql_users.sh

CMD ["/run.sh"]
