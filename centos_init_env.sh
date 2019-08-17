#!/bin/sh

alias rm=rm
alias cp=cp
alias mv=mv

sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

which "/usr/bin/systemctl" >/dev/null 2>&1
if [ $? == 0 ];then
    systemctl disable iptables
    systemctl stop iptables
    systemctl disable firewalld
    systemctl stop firewalld
else
    chkconfig --level 345 iptables off
    service iptables stop
fi

yum -y install wget
wget -O /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/CentOS-Base.repo
wget -O /etc/yum.repos.d/epel.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/epel.repo
wget -O /etc/yum.repos.d/remi.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/remi.repo
wget -O /etc/yum.repos.d/nginx.repo https://raw.githubusercontent.com/yunweibang/yum.repos.d/master/nginx.repo
yum -y update
yum -y install ansible apr apr-devel apr-util autoconf automake dos2unix expat-devel freerdp freerdp-devel \
gcc gcc-c++ java-1.8.0-openjdk java-1.8.0-openjdk-devel kde-l10n-Chinese libssh2 libssh2-devel libtool* make \
net-tools nginx ntpdate openssl openssl-devel openssl-devel openssl-libs pam-devel perl perl-devel \
subversion subversion-devel sysstat systemd-devel tomcat-native traceroute zlib-devel

which "/usr/bin/systemctl" >/dev/null 2>&1
if [ $? == 0 ];then
    for i in $(systemctl list-unit-files|egrep 'enabled'|awk '{print $1}'|egrep -v '\.target$|@\.');do
        systemctl disable $i
    done
    systemctl enable elasticsearch.service
    systemctl enable bigserver.service
    systemctl enable bigweb.service
    systemctl enable gitlab-runner.service
    systemctl enable gitlab-runsvdir.service
    systemctl enable kibana.service
    systemctl enable mysqld.service
    systemctl enable nginx.service
    systemctl enable php-fpm.service
    systemctl enable postfix.service
    systemctl enable zabbix-agent.service
    systemctl enable zabbix-server.service

    systemctl enable auditd.service
    systemctl enable crond.service
    systemctl enable rhel-autorelabel.service
    systemctl enable rhel-configure.service
    systemctl enable rhel-loadmodules.service
    systemctl enable rhel-readonly.service
    systemctl enable rsyslog.service
    systemctl enable sshd.service
    systemctl set-default multi-user.target
    echo 'LANG="zh_CN.UTF-8"'>/etc/locale.conf
    wget -O /etc/systemd/system.conf https://raw.githubusercontent.com/yunweibang/bigops-install/master/system.conf
else
    for i in $(ls /etc/rc3.d/S*|cut -c 15-|egrep -v local);do
        chkconfig --level 345 $i off
    done
    chkconfig --level 345 elasticsearch
    chkconfig --level 345 bigserver
    chkconfig --level 345 bigweb
    chkconfig --level 345 gitlab-runner
    chkconfig --level 345 gitlab-runsvdir
    chkconfig --level 345 kibana
    chkconfig --level 345 mysqld
    chkconfig --level 345 nginx
    chkconfig --level 345 php-fpm
    chkconfig --level 345 postfix
    chkconfig --level 345 zabbix-agent
    chkconfig --level 345zabbix-server

    chkconfig --level 345 sysstat on
    chkconfig --level 345 network on
    chkconfig --level 345 rsyslog on
    chkconfig --level 345 haldaemon on
    chkconfig --level 345 crond on
    chkconfig --level 345 auditd on
    chkconfig --level 345 messagebus on
    chkconfig --level 345 udev-post on
    chkconfig --level 345 sshd on
    sed -i 's/^id:.*/id:3:initdefault:/g' /etc/inittab

    yum -y groupinstall chinese-support
    echo 'LANG="zh_CN.UTF-8"'>/etc/sysconfig/i18n
    echo 'SUPPORTED="zh_CN.UTF-8:zh_CN.GB18030:zh_CN:zh:en_US.UTF-8:en_US:en"'>>/etc/sysconfig/i18n
    echo 'SYSFONT="lat0-sun16"'>>/etc/sysconfig/i18n
fi

rm -f /etc/security/limits.d/*
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/yunweibang/bigops-install/master/limits.conf
wget -O /etc/security/limits.d/90-nproc.conf https://raw.githubusercontent.com/yunweibang/bigops-install/master/90-nproc.conf

wget -O /etc/sysctl.conf https://raw.githubusercontent.com/yunweibang/bigops-install/master/sysctl.conf

sed -i '/ \/ .* defaults /s/defaults/defaults,noatime,nodiratime,nobarrier/g' /etc/fstab
cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

if [ -z "$(grep ntpdate /var/spool/cron/root)" ];then
    echo '* */6 * * * /usr/sbin/ntpdate -u pool.ntp.org && /sbin/hwclock --systohc > /dev/null 2>&1'>>/var/spool/cron/root
fi

if [ -d /var/spool/postfix/maildrop/ ];then
    if [ -z "$(grep /var/spool/postfix/maildrop/ /var/spool/cron/root)" ];then
        echo '* */6 * * * /usr/bin/find /var/spool/postfix/maildrop/ -type f |xargs rm -f > /dev/null 2>&1'>>/var/spool/cron/root
    fi
fi

for i in $(ls /sys/class/net|egrep -v 'lo|usb') ; do ethtool -K $i rx off; done
for i in $(ls /sys/class/net|egrep -v 'lo|usb') ; do ethtool -K $i tx off; done
for i in $(ls /sys/class/net|egrep -v 'lo|usb') ; do ethtool -K $i tso off; done
for i in $(ls /sys/class/net|egrep -v 'lo|usb') ; do ethtool -K $i gso off; done
for i in $(ls /sys/class/net|egrep -v 'lo|usb') ; do ethtool -K $i gro off; done

wget -O /etc/ansible/ansible.cfg https://raw.githubusercontent.com/yunweibang/bigops-config/master/ansible.cfg


if [ -z "$(egrep JAVA_HOME /etc/profile)" ];then
   echo 'export JAVA_HOME=/usr/lib/jvm/java'>>/etc/profile
   echo 'export PATH=$PATH:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/lib64:/lib64'>>/etc/profile
   echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar'>>/etc/profile
fi

if [ -z "$(egrep MAILCHECK /etc/profile)" ];then
    echo 'unset MAILCHECK'>>/etc/profile
fi

source /etc/profile

which "/usr/bin/systemctl" >/dev/null 2>&1
if [ $? != 0 ];then
    yum -y install telnet-server telnet xinetd
    wget -O /etc/xinetd.d/telnet https://raw.githubusercontent.com/yunweibang/bigops-install/master/telnet
    chkconfig telnet on
    chkconfig xinetd on
    service xinetd start
    mv /etc/securetty /etc/securetty.bak
    cd ~
    if [ -z "$(openssl version|egrep 1.0.2s)" ];then
        if [ ! -e openssl-1.0.2s.tar.gz ];then
            wget -c https://www.openssl.org/source/openssl-1.0.2s.tar.gz
        fi
        if [ -d openssl-1.0.2s ];then
            rm -rf openssl-1.0.2s
        fi
        tar zxvf openssl-1.0.2s.tar.gz
        cd openssl-1.0.2s
        ./config --prefix=/usr shared zlib
        make clean
        make && make install
    fi

    cd ~
    if [ -z "$(strings /usr/sbin/sshd | grep OpenSSH_8.0p1)" ];then
        if [ ! -e openssh-8.0p1.tar.gz ];then
            wget -c https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz
        fi
        if [ -d openssh-8.0p1 ];then
            rm -rf openssh-8.0p1
        fi
        tar zxvf openssh-8.0p1.tar.gz
        cd openssh-8.0p1
        chmod -R 0600 /etc/ssh/
        ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib --with-md5-passwords --without-openssl-header-check
        make clean
        make && make install
        cp -f ssh_config /etc/ssh/ssh_config
        echo 'StrictHostKeyChecking no' >>/etc/ssh/ssh_config
        echo 'UserKnownHostsFile=/dev/null'>>/etc/ssh/ssh_config
        cp -f sshd_config /etc/ssh/sshd_config
        sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
        sed -i 's/^GSSAPIAuthentication/#GSSAPIAuthentication no/g' /etc/ssh/sshd_config
        sed -i 's/^GSSAPICleanupCredentials/#GSSAPICleanupCredentials no/g' /etc/ssh/sshd_config
        if [ ! -z $(/usr/sbin/sshd -t -f /etc/ssh/sshd_config) ];then
            echo 'error, please run /usr/sbin/sshd -t -f /etc/ssh/sshd_config'
            exit
        fi
    fi
fi

export JAVA_HOME=/usr/lib/jvm/java
export PATH=$PATH:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/lib64:/lib64
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

cd ~
if [ ! -f /usr/local/apr/lib/libtcnative-1.a ];then
    if [ ! -e apr-1.6.5.tar.gz ];then
        wget -c http://archive.apache.org/dist/apr/apr-1.6.5.tar.gz
    fi
    if [ -d apr-1.6.5 ];then
        rm -rf apr-1.6.5
    fi
    tar zxvf apr-1.6.5.tar.gz
    cd apr-1.6.5
    ./configure --prefix=/usr/local/apr
    make && make install

    cd ~
    if [ ! -e apr-util-1.6.1.tar.gz ];then
        wget -c http://archive.apache.org/dist/apr/apr-util-1.6.1.tar.gz
    fi
    if [ -d apr-util-1.6.1 ];then
        rm -rf apr-util-1.6.1
    fi
    tar zxvf apr-util-1.6.1.tar.gz
    cd apr-util-1.6.1
    ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
    make && make install

    cd ~
    if [ ! -e tomcat-native-1.2.23-src.tar.gz ];then
        wget -c http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-connectors/native/1.2.23/source/tomcat-native-1.2.23-src.tar.gz
    fi
    if [ -d tomcat-native-1.2.23-src ];then
        rm -rf tomcat-native-1.2.23-src
    fi
    tar zxvf tomcat-native-1.2.23-src.tar.gz
    cd tomcat-native-1.2.23-src/native/
    ./configure --with-apr=/usr/local/apr --with-java-home=/usr/lib/jvm/java
    make && make install
fi
