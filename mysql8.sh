#!/bin/sh

service mysqld stop
if [ ! -z "$(ps aux|egrep -v egrep|egrep mysqld)" ];then 
   ps aux|egrep -v egrep|egrep mysqld|awk '{print $2}'|xargs kill -9
fi

if [ ! -d /opt/mysqlsoft ];then
   mkdir /opt/mysqlsoft
fi

inst(){
    wget -O /etc/my.cnf https://raw.githubusercontent.com/yunweibang/bigops-LNMP-config/master/mysql/my-8.cnf
    chmod 644 /etc/my.cnf
    rm -rf /var/lib/mysql/*
    mysqld --user=mysql --lower-case-table-names=0 --initialize-insecure
    chown -R mysql:mysql /var/lib/mysql
    systemctl restart mysqld.service
    echo
    echo ----------------------------------
    echo -e "please input root@127.0.0.1 password, default bigops"
    echo -e ">\c"
    read mypass
    if  [ -z  "${mypass}" ];then
        mypass='bigops'
    fi
    mysql -uroot -e "grant all privileges on *.* to 'root'@'127.0.0.1' identified with mysql_native_password by '${mypass}'"
    if [ $? == 0 ];then
        echo
        echo ----------------------------------
        echo "Installed successfully, root@127.0.0.1 password is ${mypass}"
        echo "please running command testing: mysql -uroot -h127.0.0.1 -p${mypass}"
        echo ----------------------------------
    else
        echo "Installed failure!"
    fi
}

osver=`rpm -qi centos-release|egrep -i version|awk '{print $3}'`
if [[ "${osver}" == 6 ]] && [[ `arch` == x86_64 ]];then
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-server-8.0.16-2.el6.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client-8.0.16-2.el6.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-common-8.0.16-2.el6.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-devel-8.0.16-2.el6.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-8.0.16-2.el6.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-compat-8.0.16-2.el6.x86_64.rpm &
    rpm -Uvh --force /opt/mysqlsoft/mysql*.el6*.rpm   
    inst
elif [[ "${osver}" == 7 ]] && [[ `arch` == x86_64 ]];then
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-server-8.0.16-2.el7.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client-8.0.16-2.el7.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-common-8.0.16-2.el7.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-devel-8.0.16-2.el7.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-8.0.16-2.el7.x86_64.rpm &
    wget -c https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-compat-8.0.16-2.el7.x86_64.rpm &
    rpm -Uvh --force /opt/mysqlsoft/mysql*.el7*.rpm
    inst
else
    echo "current system is not supported"
fi
