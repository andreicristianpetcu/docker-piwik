# -----------------------------------------------------------------------------
# docker-piwik
#
# Builds a basic docker image that can run Piwik (http://piwik.org) and serve
# all of it's assets.
#
# Authors: Isaac Bythewood
# Updated: Aug 19th, 2014
# Require: Docker (http://www.docker.io/)
# -----------------------------------------------------------------------------


# Base system is the LTS version of Ubuntu.
FROM phusion/passenger-full:0.9.12
# from   base


# Make sure we don't get notifications we can't answer during building.
ENV    DEBIAN_FRONTEND noninteractive


# An annoying error message keeps appearing unless you do this.
# RUN    dpkg-divert --local --rename --add /sbin/initctl
# RUN    ln -s /bin/true /sbin/initctl


# Download and install everything from the repos and add geo location database
# RUN    apt-get install -y -q software-properties-common
# RUN    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
# RUN    add-apt-repository -y ppa:nginx/stable
RUN    apt-get --yes update
# RUN    apt-get --yes upgrade --force-yes
# RUN    apt-get --yes install git supervisor nginx php5-mysql php5-gd mysql-server pwgen wget php5-fpm --force-yes
RUN    apt-get --yes install git nginx php5-mysql php5-gd mysql-server pwgen wget php5-fpm --force-yes
RUN    mkdir -p /srv/www/; cd /srv/www/; git clone -b master https://github.com/piwik/piwik.git --depth 1
RUN    cd /srv/www/piwik/misc; wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz; gzip -d GeoLiteCity.dat.gz
RUN    apt-get --yes install php5-cli php5-curl curl --force-yes
RUN    cd /srv/www/piwik;  curl -sS https://getcomposer.org/installer | php; php composer.phar install


# Load in all of our config files.
# add    ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD    ./nginx/sites-enabled/default /etc/nginx/sites-enabled/default
ADD    ./php5/fpm/php-fpm.conf /etc/php5/fpm/php-fpm.conf
ADD    ./php5/fpm/php.ini /etc/php5/fpm/php.ini
ADD    ./php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf
# ADD    ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
# ADD    ./supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
# ADD    ./supervisor/conf.d/mysqld.conf /etc/supervisor/conf.d/mysqld.conf
# ADD    ./supervisor/conf.d/php5-fpm.conf /etc/supervisor/conf.d/php5-fpm.conf
RUN apt-get install nmap telnet elinks -y
ADD ./mysql/mysql /build/runit/mysql
# RUN ln -s /build/runit/mysql /etc/service/mysql/run
ADD    ./mysql/my.cnf /etc/mysql/my.cnf
RUN touch /var/run/php5-fpm.sock
RUN chown www-data /var/run/php5-fpm.sock
RUN rm -f /etc/service/nginx/down
RUN chown -R www-data:www-data /srv/www/piwik
RUN chmod -R 0755 /srv/www/piwik/tmp
# ADD    ./scripts/start /start

# run /etc/init.d/php5-fpm start
RUN sed -i '/passenger/d' /etc/nginx/nginx.conf

# Fix all permissions
# RUN	   chmod +x /start; chown -R www-data:www-data /srv/www/piwik
# RUN touch /var/run/php5-fpm.sock
# RUN chmod 777 /var/run/php5-fpm.sock
ADD scripts/start_fpm.sh /etc/my_init.d/01_start_fpm.sh
ADD mysql/my.cnf /etc/mysql/my.cnf
ADD scripts/start_mysql.sh /etc/my_init.d/02_start_mysql.sh
# RUN mkdir -p /data/mysql
# install mysql-server
ADD piwik/config.ini.php srv/www/piwik/config/config.ini.php
ADD piwik/init_piwik_db.sql srv/www/piwik/init_piwik_db.sql
RUN apt-get install silversearcher-ag -y
# RUN sed -i '/piwik/d' $HOSTS_FILE
RUN echo "127.0.0.1 piwik" | tee -a $HOSTS_FILE

# 80 is for nginx web, /data contains static files and database /start runs it.
expose 80
# volume ["/data"]
# cmd    ["/start"]
ENTRYPOINT ["/sbin/my_init"]
CMD ["--enable-insecure-key"]

