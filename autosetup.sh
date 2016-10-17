#!/bin/bash
yum -y update
yum -y group install "Development tools"
yum -y install expect
path=/root/online-env-packages

rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
mkdir /opt/vip-{member,server,employee}
yum -y install openssl-devel
if [ "$?" -eq 0 ];then
tar xf ${path}/pcre-8.39.tar.gz -C ${path}
tar xf ${path}/nginx-1.10.1.tar.gz -C ${path}
useradd -r -s /sbin/nologin nginx
cd ${path}/nginx-1.10.1
./configure --prefix=/opt/nginx-forward --with-http_ssl_module --with-http_stub_status_module  --user=nginx --group=nginx --with-pcre=${path}/pcre-8.39
make -j4 && make install
mv /opt/nginx-forward/conf/nginx.conf /opt/nginx/conf/nginx.conf.bak
cp ${path}/nginx-forward-conf/nginx.conf /opt/nginx-forward/conf/
cp ${path}/nginx-forward-conf/rproxy.conf /opt/nginx-forward/conf/
/opt/nginx-forward/sbin/nginx #start nginx
echo "install nginx-forward success!"
sleep 5

else
echo "install openssl-devel has found an error!"
break;
fi

if [ "$?" -eq 0 ];then
tar xf ${path}/httpd-2.4.23.tar.gz -C ${path}
tar xf ${path}/apr-1.5.2.tar.gz -C ${path}
tar xf ${path}/apr-util-1.5.4.tar.gz -C ${path}
cd ${path}/apr-1.5.2
./configure && make -j4 &&make install
echo "install apr success!"
sleep 3

else
	echo "oh,no. install apr appears error"
	break;
fi
	if [ "$?" -eq 0 ];then
		cd ${path}/apr-util-1.5.4
		./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr && make -j4 && make install
		echo "install apr-util success!"
		sleep 3
	else
		echo "install apr-util ,unkown error appears agian"
		break;
	fi
	if [ "$?" -eq 0 ];then
		cd ${path}/httpd-2.4.23
		./configure --prefix=/opt/vip-member/apache --enable-module=so --enable-deflate=shared --enable-expires=shared  --enable-rewrite=shared --enable-cache --enable-file-cache --enable-mem-cache --enable-disk-cache --enable-static-support --enable-static-htpasswd --enable-static-htdigest --enable-static-rotatelogs --enable-authn-dbm=shared --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --with-pcre=${path}/pcre-8.39/pcre-config --enable-ssl --with-ssl
		make -j4 && make install
		cd /opt/vip-member
		/usr/bin/expect <<-EOF
		set timeout 300
		spawn git clone http://gitlab.tdrhedu.com/xyt/service-platform-member.git
		expect {
		"*'http://gitlab.tdrhedu.com':" {send "watcher\r"; exp_continue}
		"*'http://watcher@gitlab.tdrhedu.com':" {send "watcher123\r"; exp_continue}
		"#" {send "exit\r"}
		expect eof
		}
		EOF
		cp /opt/vip-member/service-platform-member/xyt/settings.py.release /opt/vip-member/service-platform-member/xyt/settings.py
		sed -i "s@ALLOWED_HOSTS = \['vip.tdrhedu.com'\]@ALLOWED_HOSTS = \['*'\]@" /opt/vip-member/service-platform-member/xyt/settings.py
		sed -i "s@'USER': '',@'USER': 'tdrhvip',@" /opt/vip-member/service-platform-member/xyt/settings.py
		sed -i "s@'PASSWORD': '',@'PASSWORD': 'tdrhEDU123',@" /opt/vip-member/service-platform-member/xyt/settings.py
		if [ "$?" -ne 0 ];then
			echo "timeout or other error"
		fi
		cp /opt/vip-member/apache/conf/httpd.conf /opt/vip-member/apache/conf/httpd.conf.bak
		cat >> /opt/vip-member/apache/conf/httpd.conf <<-EOF
LoadModule wsgi_module  modules/mod_wsgi.so

WSGIScriptAlias / /opt/vip-member/service-platform-member/xyt/wsgi.py
WSGIPythonPath /opt/vip-member/service-platform-member

        Alias /static /opt/vip-member/service-platform-member/collected_static
<Directory /opt/vip-member/service-platform-member/collected_static>
        <RequireAll>
                #Require host member-tdrhedu.com
                Require all granted
                #Require not ip 123.206.55.35
        </RequireAll>
</Directory>

<Directory /opt/vip-member/service-platform-member/xyt>
        <Files wsgi.py>
                #Require host member-tdrhedu.com
                Require all granted
        #       Require not ip 123.206.55.35
        </Files>
</Directory>
#NameVirtualHost 123.206.55.35 
#<VirtualHost *:10000> 
##ServerName 123.206.55.35
#DocumentRoot /
#<Directory />
#    Order Allow,Deny
#    Deny from 123.206.55.35
#</Directory>
#</VirtualHost>
##<VirtualHost 123.206.55.35>
##DocumentRoot "/opt/vip-member/service-platform-member/tdrenmange/" 
##ServerName www.member-tdrhedu.com
##</VirtualHost>
#<VirtualHost *:10000>
#DocumentRoot / 
#ServerName member-tdrhedu.com
#</VirtualHost>
		EOF
		sed -i "s@#ServerName www.example.com:80@ServerName www.vip.tdrhedu.com:10000@g" /opt/vip-member/apache/conf/httpd.conf
		sed -i "s@Listen 80@Listen 10000@g" /opt/vip-member/apache/conf/httpd.conf
		echo "install & config httpd success!"
		sleep 5

	else
		echo "damn,error.a.p.a.c.h.e"
		break;
	
	fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------#

#-----------#
#install pip#
#-----------#

if [ "$?" -eq 0 ];then
python ${path}/get-pip.py
yum -y install python-devel mysql-devel
pip install django==1.8.2 requests==2.10.0 mysql-python==1.2.3
echo "pip install appears problem"
break;
fi
if [ "$?" -eq 0 ];then
tar xf ${path}/mod_wsgi-4.5.3.tar.gz -C ${path}
cd ${path}/mod_wsgi-4.5.3
./configure --with-python=/usr/bin/python --with-apxs=/opt/vip-member/apache/bin/apxs
make -j4 && make install
echo "install mod_wsgi success!"
/opt/vip-member/apache/bin/apachectl start
sleep 5

else
	echo "install  wsgi appears problem"
	break;
fi
#-------------------------------------------------------------------------------------------------------------------------------------------------------#

#---------------------#
#install java & tomcat#
#---------------------#

if [ "$?" -eq 0 ];then
tar xf ${path}/jdk-8u101-linux-x64.tar.gz -C /opt/vip-server
mv /opt/vip-server/jdk1.8.0_101 /opt/vip-server/java
tar xf ${path}/apache-tomcat-8.5.4.tar.gz -C /opt/vip-server
mv /opt/vip-server/apache-tomcat-8.5.4 /opt/vip-server/tomcat8
cat >>/etc/profile<<EOF
JAVA_HOME=/opt/vip-server/java
CATALINA_HOME=/opt/vip-server/tomcat8
JRE_HOME=/opt/vip-server/java/jre
PATH=\$JAVA_HOME/bin:\$CATALINA_HOME/bin:\$JRE_HOME/bin:\$PATH
export JAVA_HOME CATALINA_HOME JRE_HOME  PATH
EOF
. /etc/profile
java -version

if [ "$?" -ne 0 ];then
echo "java env not set correctly"
fi
sleep 6
cp ${path}/service_platform.war /opt/vip-server/tomcat8/webapps
sed -i "s@Connector port="8080"@Connector port="11000"@g" /opt/vip-server/tomcat8/conf/server.xml
/opt/vip-server/tomcat8/bin/startup.sh
sed -i "s@server.mysql.username=root@server.mysql.username=tdrhvip@g" /opt/vip-server/tomcat8/webapps/service_platform/WEB-INF/classes/application-prod.properties
sed -i "s@server.mysql.password=tdrhedu@server.mysql.password=tdrhEDU123@g" /opt/vip-server/tomcat8/webapps/service_platform/WEB-INF/classes/application-prod.properties
sed -i "s@server.redis.password=tdrhedu1234@server.redis.password=@g" /opt/vip-server/tomcat8/webapps/service_platform/WEB-INF/classes/application-prod.properties
/opt/vip-server/tomcat8/bin/shutdown.sh
echo "install & configured java & tomcat success!"
sleep 5

else
	echo "install java & tomcat appears problem"
	break;
fi

#-------------------------------------------------------------------------------------------------------------------------------------------------------#

#-------------------#
#install nginx & php#
#-------------------#

if [ "$?" -eq 0 ];then
yum -y install libxml2-devel bzip2-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libcurl libcurl-devel libxslt-devel openssl-devel libmcrypt libmcrypt-devel readline-devel recode recode-devel libtidy libtidy-devel
tar xf ${path}/php-5.6.25.tar.tar -C ${path}
cd ${path}/php-5.6.25
./configure --prefix=/opt/php5.6 --sysconfdir=/etc/php_conf --with-config-file-path=/etc/php_conf --enable-fpm --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-mhash --with-openssl --with-zlib --with-bz2 --with-curl --with-libxml-dir --with-gd --with-jpeg-dir --with-png-dir --with-zlib --enable-mbstring --with-mcrypt --enable-sockets --with-iconv-dir --with-xsl --enable-zip --with-pcre-dir --with-pear --enable-session  --enable-gd-native-ttf --enable-xml --with-freetype-dir --enable-gd-jis-conv --enable-inline-optimization --enable-shared --enable-bcmath --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-mbregex --enable-pcntl --with-xmlrpc --with-gettext --enable-exif --with-readline --with-recode --with-tidy
make -j4 && make install
#################initail php###########################################
cp /etc/php_conf/php-fpm.conf.default /etc/php_conf/php-fpm.conf
cp ${path}/php-5.6.25/sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm
chmod a+x /etc/rc.d/init.d/php-fpm
chkconfig --add php-fpm
systemctl enable php-fpm
cp ${path}/php-5.6.25/php.ini-production  /opt/php5.6/lib/php.ini
#######################################################################
/etc/init.d/php-fpm start
echo "install php5.6 success!"
sleep 5
else
	echo "install failed"
	break;
fi
if [ "$?" -ne 0 ];then
echo "install php failed"
break;
else
cd ${path}/nginx-1.10.1
./configure --prefix=/opt/vip-employee/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-pcre=${path}/pcre-8.39
make -j4 && make install
cd /opt/vip-employee/nginx/html
/usr/bin/expect <<-EOF
set timeout 300
spawn git clone http://gitlab.tdrhedu.com/xyt/service-platform-employee.git
expect {
"*'http://gitlab.tdrhedu.com':" {send "watcher\r"; exp_continue}
"*'http://watcher@gitlab.tdrhedu.com':" {send "watcher123\r"; exp_continue}
"#" {send "exit\r"}
expect eof
}
EOF
cp /opt/vip-employee/nginx/html/service-platform-employee/think/backstage/Common/Conf/config.release.php /opt/vip-employee/nginx/html/service-platform-employee/think/backstage/Common/Conf/config.php
sed -i "s@'DB_HOST'         => 'http://101.200.221.231/',@'DB_HOST'         => 'http://127.0.0.1/',@g" /opt/vip-employee/nginx/html/service-platform-employee/think/backstage/Common/Conf/config.php
sed -i "s@'DB_USER'         => 'root',@'DB_USER'         => 'tdrhvip',@g" /opt/vip-employee/nginx/html/service-platform-employee/think/backstage/Common/Conf/config.php
sed -i "s@'DB_PWD'          => 'tdrhedu',@'DB_PWD'          => 'tdrhEDU123',@g" /opt/vip-employee/nginx/html/service-platform-employee/think/backstage/Common/Conf/config.php
if [ "$?" -ne 0 ];then
echo "config employee config.php error"
fi
sleep 5
cp /opt/vip-employee/nginx/conf/nginx.conf /opt/vip-employee/nginx/conf/nginx.conf.bak
cp ${path}/nginx.conf /opt/vip-employee/nginx/conf
chmod 777 -R /opt/vip-employee/nginx/html/service-platform-employee
/opt/vip-employee/nginx/sbin/nginx
echo "install nginx success!"
sleep 3
fi

#-------------------------------------------------------------------------------------------------------------------------------------------------------#

#-----------------------#
#install mariadb & redis#
#-----------------------#

yum -y install cmake ncurses-devel
useradd -r -s /sbin/nologin mysql
tar xf ${path}/mysql-5.6.32.tar.gz -C ${path}
cd ${path}/mysql-5.6.32
cmake . -DCMAKE_INSTALL_PREFIX=/opt/mysql -DMYSQL_DATADIR=/opt/mysql/data -DSYSCONFDIR=/opt/mysql/conf -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DMYSQL_UNIX_ADDR=/opt/mysql/sock/mysqld.sock -DENABLED_LOCAL_INFILE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DEXTRA_CHARSETS=all -DMYSQL_USER=mysql
make -j4 && make install
chown -R mysql.mysql /opt/mysql
mv /etc/my.cnf /etc/my.cnf.bak
#########################################initail mariadb#######################################
/opt/mysql/scripts/mysql_install_db --user=mysql --basedir=/opt/mysql --datadir=/opt/mysql/data --pid-file=/opt/mysql/mysqld.pid --log-error=/opt/mysql/log/mysql_error.log
###############################################################################################
if [ "$?" -eq 0 ];then
cp /opt/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
chmod 755 /etc/init.d/mysqld
chkconfig --add mysqld
echo "export PATH=$PATH:/opt/mysql/bin" >> /etc/profile
. /etc/profile
/etc/init.d/mysqld start
mysqladmin -uroot password 'tdrhedu'
mysql -uroot -ptdrhedu -e "create database service_platform default charset utf8;"
mysql -uroot -ptdrhedu -e "create database vip_member default charset utf8;"
mysql -uroot -ptdrhedu -e "grant all on vip_member.* to 'tdrhvip'@'localhost' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "grant all on vip_member.* to 'tdrhvip'@'127.0.0.1' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "grant all on vip_member.* to 'tdrhvip'@'%' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "grant all on service_platform.* to 'tdrhvip'@'localhost' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "grant all on service_platform.* to 'tdrhvip'@'127.0.0.1' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "grant all on service_platform.* to 'tdrhvip'@'%' identified by 'tdrhEDU123';"
mysql -uroot -ptdrhedu -e "flush privileges;"
mysql -utdrhvip -ptdrhEDU123 service_platform < ${path}/backup-service_platform-2016-09-07-12_00_01.sql
echo "install mariadb success!"
cd /opt/vip-member/service-platform-member
python manage.py migrate
/usr/bin/expect <<-EOF
set timeout 30
spawn python manage.py collectstatic
expect {
"*'no' to cancel:" {send "yes\r"; exp_continue}
"#" {send "exit\r"}
expect eof
}
EOF
/opt/vip-member/apache/bin/apachectl restart
/opt/vip-server/tomcat8/bin/startup.sh
sleep 5

else
	echo "mariadb install failed"
	break;
fi

if [ "$?" -eq 0 ];then
tar xf ${path}/redis-3.2.1.tar.gz -C ${path}
cd ${path}/redis-3.2.1
make && make install
cd ${path}/redis-3.2.1/utils
/usr/bin/expect <<-EOF
set timeout 10
spawn ./install_server.sh
expect {
"*instance:" {send "\r"; exp_continue}
"*config file name" {send "/opt/redis/redis.conf\r"; exp_continue}
"*log file name" {send "/opt/redis/log/redis.log\r"; exp_continue}
"*this instance" {send "/opt/redis/data\r"; exp_continue}
"*executable path" {send "\r"; exp_continue}
"*abort." {send "\r"; exp_continue}
"#" {send "exit\r"}
expect eof
}
EOF
/usr/local/bin/redis-server /opt/redis/redis.conf
echo "all programs has been done!"
else
	echo "install redis failed"
	break;
fi
