#!/bin/sh
# Basic script (idea) for a quick install of a webserver
# environment on a fresh Ubuntu Natty system
#
# Creates the base for a TYPO3 powered website
#
# Released under Public Domain, no copyright and no license applied in any way.
# Use as you wish to, but don't complain if it does not work.
#
# Inspired by the script https://github.com/till/ubuntu/blob/master/ec2/configure-php.sh 
# Written by Till Klampaeckel (till@php.net)
#
# This script makes use of his work, as published under BSD license at https://github.com/till/ubuntu

# Wee need to be the root of all evil
sudo -s

# Add MariaDB repository
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 1BB943DB

echo "deb http://mirrors.fe.up.pt/pub/mariadb/repo/5.2/ubuntu natty main" > /etc/apt/sources.list.d/mariadb.list
echo "deb-src http://mirrors.fe.up.pt/pub/mariadb/repo/5.2/ubuntu natty main" >> /etc/apt/sources.list.d/mariadb.list

# Add nginx repository
nginx=stable
add-apt-repository ppa:nginx/$nginx

# Install components
apt-get update 
apt-get install nginx mariadb-server-5.2 php5-cgi php5-cli php5-curl php5-gd php5-mysql php5-xcache php-pear php5-dev graphicsmagick ghostscript

# Configure PHP extensions
pecl install igbinary

echo "extension=igbinary.so" > /etc/php5/conf.d/igbinary.ini
echo "session.serialize_handler=igbinary" > /etc/php5/conf.d/igbinary.ini
echo "igbinary.compact_strings=Off" > /etc/php5/conf.d/igbinary.ini

wget https://github.com/till/ubuntu/raw/master/php-fcgid/php-fcgid

# Configure
sed 's/"johndoe jandoe"/"www-data"/' php-fcgid | sed 's/"2"/"10"/' - | sed 's/"100"/"1000"/' - > php-fcgid
chmod +x php-fcgid
mv php-fcgid /etc/init.d
update-rc.d php-fcgid defaults

# Configure php.ini
# From https://github.com/till/ubuntu/blob/master/ec2/configure-php.sh
# Credits to Till Klampaeckel (till@php.net)
php_ini=/etc/php5/cgi/php.ini
php_log=/var/log/php-error.log
www_user=www-data


touch $php_log
chown $www_user:$www_user $php_log

# turn on error logging, turn off display of errors
sed -i "s,log_errors = Off,log_errors = On,g" $php_ini
sed -i "s,display_errors = On,display_errors = Off,g" $php_ini
sed -i "s,;error_log = filename,error_log = $php_log,g" $php_ini

# hide PHP
sed -i "s,expose_php = On,expose_php = Off,g" $php_ini

# realpath cache
sed -i "s,; realpath_cache_size=16k,realpath_cache_size=128k,g" $php_ini
sed -i "s,; realpath_cache_ttl=120,realpath_cache_ttl=3600,g" $php_ini

# up the memory_limit and max_execution_time
sed -i "s,memory_limit = 16M,memory_limit = 256M,g" $php_ini
sed -i "s,max_execution_time = 30,max_execution_time = 60,g" $php_ini

# fix ubuntu fuck ups
sed -i "s,magic_quotes_gpc = On,magic_quotes_gpc = Off,g" $php_ini

# don't stat on each access
sed -i "s,xcache.stat   =               On,xcache.stat   =               Off,g" /etc/php5/conf.d/xcache.ini

# update PEAR
pear channel-update pear.php.net
pear upgrade-all


# Configure base TYPO3 host
wget https://github.com/Trenker/ubuntu-tools/raw/master/tools/default-host.conf
mv default-host.conf /etc/nginx/sites-enabled
