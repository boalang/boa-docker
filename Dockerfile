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

RUN cd /app; drush dl drupal-7 ; mv drupal-7.* boa
RUN cd /app/boa/sites/all/modules ; git clone https://github.com/boalang/drupal.git boa

RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes openjdk-11-jre

#RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes openjdk-11-jre npm nodejs
#RUN cd /tmp ; git clone https://github.com/boalang/ace.git
#RUN cd /tmp/ace ; npm install --no-audit ; nodejs /tmp/ace/Makefile.dryice.js full --target /app/boa/sites/all/libraries/ace

CMD ["/run.sh"]
