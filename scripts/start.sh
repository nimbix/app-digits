#!/bin/sh

set -x
sudo service ssh start >/dev/null 2>&1

DIGITS_DATA_DIR=/data/DIGITS/jobs

mkdir -p $DIGITS_DATA_DIR

service nginx start

if [ -r /etc/bitfusionio/adaptor.conf -a -x /usr/bin/bfboost ]; then
    BITFUSION=1
fi

# digits-server assumes this working directory
cd /usr/share/digits/

if [ ! -z $BITFUSION ]; then
    bfboost client /usr/share/digits/digits-server >> /var/log/digits/digits.log 2>&1 &
else
    /usr/share/digits/digits-server >> /var/log/digits/digits.log 2>&1 &
fi

sudo tail -f /var/log/nginx/error.log
