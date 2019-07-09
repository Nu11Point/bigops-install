#!/bin/sh

stty erase '^H'

/bin/sh /opt/bigops/bin/check_env.sh

cp -f /opt/bigops/install/yum.repos.d/* /etc/yum.repos.d/

which "nginx" > /dev/null
if [ $? != 0 ];then
    yum -y install nginx
fi

if [ ! -d /opt/ngxlog/ ];then
    mkdir /opt/ngxlog
fi

cp -f /opt/bigops/config/bigops.properties.example /opt/bigops/config/bigops.properties

echo -e "please input sso url, for example: sso.bigops.com"
echo -e ">\c"
read ssourl
ssourl=`echo "$ssourl"|sed 's/[ ]*//g'`

echo -e "please input homeurl, for example: work.bigops.com"
echo -e ">\c"
read homeurl
homeurl=`echo "$homeurl"|sed 's/[ ]*//g'`

cp -f /opt/bigops/install/lnmp_conf/nginx.conf /etc/nginx/nginx.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/default.conf /etc/nginx/conf.d/default.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/sso.conf /etc/nginx/conf.d/sso.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/work.conf /etc/nginx/conf.d/work.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/zabbix.conf /etc/nginx/conf.d/zabbix.conf

sed -i "s#^[ \t]*server_name.*#    server_name ${ssourl};#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*server_name.*#    server_name ${homeurl};#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${ssourl}.access.log main;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${homeurl}.access.log main;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${ssourl}.error.log;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${homeurl}.error.log;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^sso.url=.*#sso.url=http://${ssourl}#g" /opt/bigops/config/bigops.properties
sed -i "s#^home.url=.*#home.url=http://${homeurl}#g" /opt/bigops/config/bigops.properties

echo -e "please input db host >\c"
read dbhost

echo -e "please input db port >\c"
read dbport

echo -e "please input db name >\c"
read dbname

echo -e "please input db user >\c"
read dbuser

echo -e "please input db pass >\c"
read dbpass

sed -i "s#^spring.datasource.url=.*#spring.datasource.url=jdbc:mysql://${dbhost}:${dbport}/${dbname}\?useSSL=false\&useUnicode=true\&autoReconnect=true\&characterEncoding=UTF-8\&allowPublicKeyRetrieval=true#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.username=.*#spring.datasource.username=${dbuser}#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.password=.*#spring.datasource.password=${dbpass}#g" /opt/bigops/config/bigops.properties

mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "drop database if exists ${dbname}" 2>/dev/null
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "create database ${dbname}" 2>/dev/null
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} ${dbname} </opt/bigops/install/mysql/bigops-1.0.0.sql 2>/dev/null

echo "please run /bin/sh /opt/bigops/bin/restart.sh"
