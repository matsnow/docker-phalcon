FROM centos:centos6.7

MAINTAINER masayuki.matsuo <matsuo.masayuki.0415@gmail.com>

# system update
RUN yum -y update && yum install -y initscripts wget gcc make make tar gcc-c++

# install redis
WORKDIR /usr/local/src
RUN wget http://download.redis.io/releases/redis-2.8.12.tar.gz
RUN tar -xzvf redis-2.8.12.tar.gz
WORKDIR /usr/local/src/redis-2.8.12
RUN make && make install
ADD ./redis/redis.conf /etc/redis.conf

# postfix
RUN yum  -y install postfix

# install mariadb
ADD ./mariadb/MariaDB.repo /etc/yum.repos.d/MariaDB.repo
RUN yum install -y MariaDB-server
RUN yum install -y MariaDB-client
RUN yum install -y MariaDB-devel
ADD ./mariadb/transaction-isolation.cnf /etc/my.cnf.d/transaction-isolation.cnf

# install APR
WORKDIR /usr/local/src
RUN wget http://www.us.apache.org/dist//apr/apr-1.5.2.tar.gz
RUN tar -zxvf apr-1.5.2.tar.gz
WORKDIR /usr/local/src/apr-1.5.2
RUN ./configure --prefix=/opt/apr/apr-1.5.2 && make && make install

# install APR-util
WORKDIR /usr/local/src
RUN wget http://www.us.apache.org/dist//apr/apr-util-1.5.4.tar.gz
RUN tar -xzvf apr-util-1.5.4.tar.gz
WORKDIR /usr/local/src/apr-util-1.5.4
RUN ./configure --prefix=/opt/apr-util/apr-util-1.5.4 --with-apr=/opt/apr/apr-1.5.2
RUN make && make install

# install pcre & openssl
RUN  yum install -y pcre-devel  openssl-devel  libxml2-devel curl-devel libpng-devel

# install apache
WORKDIR /usr/local/src
RUN wget http://ftp.kddilabs.jp/infosystems/apache//httpd/httpd-2.4.20.tar.gz
RUN tar -xzvf httpd-2.4.20.tar.gz
WORKDIR /usr/local/src/httpd-2.4.20
RUN  ./configure --enable-so --enable-ssl --enable-rewrite --with-apr=/opt/apr/apr-1.5.2 --with-apr-util=/opt/apr-util/apr-util-1.5.4
RUN make && make install

# install mcypt
WORKDIR /usr/local/src
RUN wget 'http://osdn.jp/frs/g_redir.php?m=kent&f=%2Fmcrypt%2FLibmcrypt%2F2.5.8%2Flibmcrypt-2.5.8.tar.gz' -O libmcrypt-2.5.8.tar.gz
RUN tar -xzvf libmcrypt-2.5.8.tar.gz

WORKDIR libmcrypt-2.5.8
RUN ./configure --disable-posix-threads
RUN make install

# install php
WORKDIR /usr/local/src
RUN wget --max-redirect=3 -O php-7.0.9.tar.gz http://jp2.php.net/get/php-7.0.9.tar.gz/from/this/mirror
RUN tar -xzvf php-7.0.9.tar.gz
WORKDIR /usr/local/src/php-7.0.9
RUN  ./configure --with-apxs2=/usr/local/apache2/bin/apxs --with-mysql --with-zlib --enable-mysqlnd --enable-zip --with-xml --with-curl --with-hash --with-pdo --enable-mbstring --with-pdo-mysql --with-openssl --with-mcrypt=/usr/local
RUN make && make install

# install apcu
RUN echo yes | pecl install apcu-4.0.11

# install git
RUN yum -y install git

# install phalcon
WORKDIR /usr/local/src
RUN git clone --depth=1 https://github.com/phalcon/cphalcon.git
WORKDIR /usr/local/src/cphalcon/build
RUN ./install

# install php-redis
WORKDIR /usr/local/src
RUN git clone https://github.com/nicolasff/phpredis.git -b php7
WORKDIR /usr/local/src/phpredis
RUN phpize
RUN ./configure
RUN make && make install
WORKDIR /root

# install xdebug
RUN pecl install xdebug-2.4.0

# setting php.ini
RUN cp /usr/local/src/php-7.0.9/php.ini-development /usr/local/lib/php.ini
RUN sed -i -e 's/;date.timezone =/date.timezone = Asia\/Tokyo/g' /usr/local/lib/php.ini
RUN echo "[xdebug]" >> /usr/local/lib/php.ini
RUN echo "zend_extension=/usr/local/lib/php/extensions/no-debug-zts-20131226/xdebug.so" >> /usr/local/lib/php.ini
RUN echo "[apuc]" >> /usr/local/lib/php.ini
RUN echo "extension=apcu.so" >> /usr/local/lib/php.ini
RUN echo "[redis]" >> /usr/local/lib/php.ini
RUN echo "extension=redis.so" >> /usr/local/lib/php.ini
RUN echo "[phalcon]" >> /usr/local/lib/php.ini
RUN echo "extension=phalcon.so" >> /usr/local/lib/php.ini
RUN echo "" >> /usr/local/lib/php.ini
RUN echo "always_populate_raw_post_data=-1" >> /usr/local/lib/php.ini
RUN echo "pdo_mysql.default_socket=/var/lib/mysql/mysql.sock" >> /usr/local/lib/php.ini

# setting apache
RUN sed -i -e 's/#LoadModule ssl_module /LoadModule ssl_module /g' /usr/local/apache2/conf/httpd.conf
RUN sed -i -e 's/#LoadModule socache_shmcb_module /LoadModule socache_shmcb_module /g' /usr/local/apache2/conf/httpd.conf
RUN sed -i -e 's/#LoadModule rewrite_module /LoadModule rewrite_module /g' /usr/local/apache2/conf/httpd.conf
ADD ./apache/server.key /usr/local/apache2/conf/server.key
ADD ./apache/server.crt /usr/local/apache2/conf/server.crt
ADD ./apache/server.csr /usr/local/apache2/conf/server.csr
ADD ./apache/local.conf /usr/local/apache2/conf/extra/httpd-local.conf
RUN echo "Include conf/extra/httpd-local.conf" >> /usr/local/apache2/conf/httpd.conf

# set environment path
ENV PATH $PATH:/usr/local/apache2/bin

# add www user
RUN useradd -u 1000 -s /bin/bash -m www
RUN sed -i -e 's/User daemon/User www/g'   /usr/local/apache2/conf/httpd.conf
RUN sed -i -e 's/Group daemon/Group www/g' /usr/local/apache2/conf/httpd.conf

# start service
ADD commands.sh /usr/local/bin/commands.sh
CMD /usr/local/bin/commands.sh
