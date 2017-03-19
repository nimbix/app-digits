#!/bin/bash

# http://docs.gunicorn.org/en/stable/settings.html

for i in /etc/profile.d/*; do
    source $i
done

sudo service nginx start
sudo service ssh start

cd /opt/digits

. /etc/JARVICE/jobinfo.sh

sed -i "s/{{hostname}}/${JOB_PUBLICADDR}/g" /opt/digits/digits/digits.cfg

cd /opt/digits

export DIGITS_JOBS_DIR=/data/DIGITS/jobs
mkdir -p ${DIGITS_JOBS_DIR}

DIGITS_FORCE_SSL=1
export DIGITS_FORCE_SSL

python digits -p 34448

#gunicorn --certfile /etc/JARVICE/cert.pem --keyfile /etc/JARVICE/cert.pem --config gunicorn_config.py digits.webapp:app 2>&1 | tee -a /var/log/digits/digits.log
