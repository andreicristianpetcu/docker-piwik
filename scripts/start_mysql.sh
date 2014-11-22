#!/usr/bin/env bash
/etc/init.d/mysql start
mysql --user=root -e "drop database if exists piwik;"
mysql --user=root -e "create database piwik;"
mysql --user=root -e "grant all on *.* to 'piwik'@'%' identified by 'piwik';"
sed -i 's/172.17.0.2/piwik/g' srv/www/piwik/config/config.ini.php
sed -i 's/172.17.0.2/piwik/g' srv/www/piwik/init_piwik_db.sql
mysql -u piwik -ppiwik piwik < /srv/www/piwik/init_piwik_db.sql
