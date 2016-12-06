#!/bin/sh

# http://docs.gunicorn.org/en/stable/settings.html

sudo service nginx start

cd /usr/share/digits

. /etc/JARVICE/jobinfo.sh

sed -i "s/{{hostname}}/${JOB_PUBLICADDR}/g" /usr/share/digits/digits/digits.cfg

mkdir -p /data/DIGITS/jobs

cd /usr/share/digits

export CAFFE_ROOT=/opt/caffe-nv
export DIGITS_JOBS_DIR=/data/DIGITS/jobs
mkdir -p ${DIGITS_JOBS_DIR}

#export TORCH_ROOT=/usr/local/torch-nv

cd /usr/share/digits
python digits -p 34448
