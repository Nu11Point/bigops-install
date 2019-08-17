#!/bin/sh

if [ -d /var/spool/clientmqueue ];then
    /usr/bin/find /var/spool/clientmqueue -type f |xargs rm -f
fi

if [ -d /var/spool/postfix/maildrop/ ];then
    /usr/bin/find /var/spool/postfix/maildrop/ -type f |xargs rm -f
fi
