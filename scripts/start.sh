#!/bin/bash

# http://docs.gunicorn.org/en/stable/settings.html

sudo service nginx start

cd /usr/share/digits

. /etc/JARVICE/jobinfo.sh

sed -i "s/{{hostname}}/${JOB_PUBLICADDR}/g" /usr/share/digits/digits/digits.cfg

mkdir -p /data/DIGITS/jobs

cd /usr/share/digits

if [ -f /opt/DL/caffe-nv/bin/caffe-activate ]; then
    . /opt/DL/caffe-nv/bin/caffe-activate
fi

if [ -f /opt/DL/torch/torch-activate ]; then
    . /opt/DL/torch/torch-activate
fi

export DIGITS_JOBS_DIR=/data/DIGITS/jobs
mkdir -p ${DIGITS_JOBS_DIR}

cd /usr/share/digits
python digits -p 34448
