#!/bin/sh

stty erase '^H'

setenforce 0
if [ -f /etc/sysconfig/selinux ];then
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
fi
if [ -f /etc/selinux/config ];then
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

/bin/sh /opt/bigops/bin/check_env.sh

wget -O /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/CentOS-Base.repo
wget -O /etc/yum.repos.d/epel.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/epel.repo
wget -O /etc/yum.repos.d/mysql-community.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/mysql-community.repo
wget -O /etc/yum.repos.d/nginx.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/nginx.repo
wget -O /etc/yum.repos.d/remi.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/remi.repo

which "make" > /dev/null
if [ $? != 0 ];then
    yum -y install make
fi

which "gcc" > /dev/null
if [ $? != 0 ];then
    yum -y install gcc
fi

which "g++" > /dev/null
if [ $? != 0 ];then
    yum -y install gcc-c++
fi

medusainst(){
    yum -y install openssl openssl-libs openssl-devel
    cd /opt/bigops/install/soft/
    tar zxvf libssh2-1.8.2.tar.gz
    cd libssh2-1.8.2
    ./configure --prefix=/usr
    make && make install
    cd /opt/bigops/install/soft/
    tar zxvf medusa-2.2.tar.gz
    cd medusa-2.2
    ./configure --prefix=/usr --enable-module-ssh=yes
    make && make install
}

which "/usr/bin/medusa" > /dev/null
if [ $? != 0 ];then
    medusainst
else
    if [ -z "$(/usr/bin/medusa -d|grep ssh.mod)" ];then
        medusainst
    fi
    if [ -z "$(/usr/bin/medusa -V|egrep v2.2)" ];then
        medusainst
    fi
fi

if [ -z "$(/usr/bin/nmap -V|egrep 7.70)" ];then
    cd /opt/bigops/install/soft/
    tar zxvf nmap-7.70.tgz
    cd nmap-7.70
    ./configure --prefix=/usr
    make && make install
fi

yum -y update openssh-clients
which "/usr/bin/ansible" > /dev/null
if [ $? != 0 ];then
    yum -y install ansible
fi
cp -f /opt/bigops/install/ansible.cfg /root/.ansible.cfg
sed -i 's/^[ ]*StrictHostKeyChecking.*/StrictHostKeyChecking no/g' /etc/ssh/ssh_config

if [ -f /usr/bin/jqbak ];then
    cp -f /opt/bigops/install/soft/jq-linux64 /usr/bin/jq
else
    cp  /usr/bin/jq /usr/bin/jqbak
    cp -f /opt/bigops/install/soft/jq-linux64 /usr/bin/jq
fi
chmod 777 /usr/bin/jq

which "/usr/sbin/nginx" > /dev/null
if [ $? != 0 ];then
    yum -y install nginx
fi

if [ ! -d /opt/ngxlog/ ];then
    mkdir /opt/ngxlog
fi

wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/yunweibang/bigops-config/master/nginx/nginx.conf
wget -O /etc/nginx/conf.d/default.conf https://raw.githubusercontent.com/yunweibang/bigops-config/master/nginx/conf.d/default.conf
wget -O /etc/nginx/conf.d/sso.conf https://raw.githubusercontent.com/yunweibang/bigops-config/master/nginx/conf.d/sso.conf
wget -O /etc/nginx/conf.d/work.conf https://raw.githubusercontent.com/yunweibang/bigops-config/master/nginx/conf.d/work.conf
wget -O /etc/nginx/conf.d/zabbix.conf https://raw.githubusercontent.com/yunweibang/bigops-config/master/nginx/conf.d/zabbix.conf

cp -f /opt/bigops/config/bigops.properties.example /opt/bigops/config/bigops.properties

echo
echo
echo ----------------------------------
echo -e "please input sso url, default sso.bigops.com"
echo -e ">\c"
read ssourl
ssourl=`echo "${ssourl}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
if [ -z "${ssourl}" ];then
    ssourl='sso.bigops.com'
fi

echo -e "please input home url, default work.bigops.com"
echo -e ">\c"
read homeurl
homeurl=`echo "${homeurl}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
if [ -z "${homeurl}" ];then
    homeurl='work.bigops.com'
fi


sed -i "s#^[ \t]*server_name.*#    server_name ${ssourl};#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*server_name.*#    server_name ${homeurl};#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${ssourl}.access.log main;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${homeurl}.access.log main;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${ssourl}.error.log;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${homeurl}.error.log;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^sso.url=.*#sso.url=http://${ssourl}#g" /opt/bigops/config/bigops.properties
sed -i "s#^home.url=.*#home.url=http://${homeurl}#g" /opt/bigops/config/bigops.properties

echo -e "please input db host, default 127.0.0.1"
echo -e ">\c"
read dbhost

echo -e "please input db port, default 3306"
echo -e ">\c"
read dbport

echo -e "please input db name, default bigops"
echo -e ">\c"
read dbname

echo -e "please input db user, default root"
echo -e ">\c"
read dbuser

echo -e "please input db pass"
echo -e ">\c"
read dbpass

if [ -z "${dbhost}" ];then
    dbhost='127.0.0.1'
fi
if [ -z "${dbport}" ];then
    dbport='3306'
fi
if [ -z "${dbname}" ];then
    dbname='bigops'
fi
if [ -z "${dbuser}" ];then
    dbuser='root'
fi
if [ -z "${dbpass}" ];then
    echo 'please input db pass'
    exit
fi

dbhost=`echo "${dbhost}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbport=`echo "${dbport}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbname=`echo "${dbname}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbuser=`echo "${dbuser}"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`

sed -i "s#^spring.datasource.url=.*#spring.datasource.url=jdbc:mysql://${dbhost}:${dbport}/${dbname}\
\?useSSL=false\&useUnicode=true\&autoReconnect=true\&characterEncoding=UTF-8#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.username=.*#spring.datasource.username=${dbuser}#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.password=.*#spring.datasource.password=${dbpass}#g" /opt/bigops/config/bigops.properties

echo
echo ----------------------------------
mysqladmin -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} drop ${dbname} 2>/dev/null
if [ $? != 0 ];then echo "installation failed.code 1 exit";fi

echo
echo ----------------------------------
echo 'test command'
echo mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport}
echo
echo ----------------------------------

mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "create database ${dbname}" 2>/dev/null
if [ $? != 0 ];then echo "installation failed. code 2 exit";exit;fi

mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} ${dbname} </opt/bigops/install/mysql/bigops-1.0.0.sql 2>/dev/null
if [ $? != 0 ];then echo "installation failed. code 3 exit";exit;fi

echo 'Display installed database'
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "show databases like '${dbname}'" 2>/dev/null
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "use ${dbname};show tables like '%egistered%'" 2>/dev/null
if [ $? == 0 ];then
    echo
    echo ----------------------------------
    /bin/sh /opt/bigops/bin/restart.sh
else
    echo "installation failed. code 4 exit"
fi
