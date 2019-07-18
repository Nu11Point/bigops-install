#!/bin/sh

which "/usr/bin/systemctl" >/dev/null 2>&1
if [ $? == 0 ];then
    systemctl stop mysqld.service
else
    service mysqld stop
fi

if [ ! -z "$(ps aux|egrep mysqld|grep -v grep)" ];then 
   ps aux|egrep mysqld|grep -v grep|awk '{print $2}'|xargs kill -9
fi

if [ ! -d /opt/mysql-rpms ];then
   mkdir /opt/mysql-rpms
fi

inst(){
    if [ ! -f /usr/sbin/mysqld ];then
        echo "not found /usr/sbin/mysqld, installation failed"
        exit
    fi
    wget -O /etc/my.cnf https://raw.githubusercontent.com/yunweibang/bigops-config/master/mysql/my-57.cnf
    chmod 644 /etc/my.cnf
    rm -rf /var/lib/mysql/*
    mysqld --user=mysql --lower-case-table-names=0 --initialize-insecure
    chown -R mysql:mysql /var/lib/mysql

    which "/usr/bin/systemctl" >/dev/null 2>&1
    if [ $? == 0 ];then
        systemctl start mysqld.service
    else
        service mysqld start
    fi

    echo
    echo ----------------------------------
    echo "press any key to continue"
    read

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

osver=`rpm -qi centos-release|egrep Version|awk '{print $3}'`
cd /opt/mysql-rpms/
if [[ "${osver}" == 6 ]] && [[ `arch` == x86_64 ]];then
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-client-5.7.26-1.el6.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-common-5.7.26-1.el6.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-devel-5.7.26-1.el6.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-libs-5.7.26-1.el6.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-libs-compat-5.7.26-1.el6.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-server-5.7.26-1.el6.x86_64.rpm
    rm -f /etc/init.d/mysqld
    rpm -Uvh --force /opt/mysql-rpms/*-5.7*.el6.*.rpm   
    inst
elif [[ "${osver}" == 7 ]] && [[ `arch` == x86_64 ]];then
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-client-5.7.26-1.el7.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-common-5.7.26-1.el7.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-devel-5.7.26-1.el7.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-libs-5.7.26-1.el7.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-libs-compat-5.7.26-1.el7.x86_64.rpm &
    wget -N -c https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-server-5.7.26-1.el7.x86_64.rpm
    rpm -Uvh --force /opt/mysql-rpms/*-5.7*.el7.*.rpm
    inst
else
    echo "current system is not supported"
fi
