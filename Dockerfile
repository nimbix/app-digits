FROM nimbix/base-ubuntu-nvidia
MAINTAINER Nimbix, Inc.

USER root
RUN apt-get update && \
    apt-get install --no-install-recommends -y --force-yes \
	git \
	graphviz \
	python-dev \
	python-flask \
	python-flaskext.wtf \
	python-gevent \
	python-h5py \
	python-numpy \
	python-pil \
	python-pip \
	python-protobuf \
	python-scipy \
        libpng12-0 \
	libpng12-dev \
	libfreetype6 \
	libfreetype6-dev && \
        apt-get build-dep -y --force-yes python-matplotlib && \
        apt-get clean

WORKDIR /usr/share
RUN git clone https://github.com/nimbix/DIGITS.git digits
ENV DIGITS_ROOT=/usr/share/digits
WORKDIR ${DIGITS_ROOT}
RUN git checkout digits-5.0-https
RUN sudo pip install -r $DIGITS_ROOT/requirements.txt
RUN sudo pip install -e $DIGITS_ROOT

# Install Caffe
WORKDIR /tmp
USER nimbix
RUN sudo apt-get install -y devscripts \
    dh-make \
    build-essential && sudo apt-get clean && \
    git clone https://github.com/NVIDIA/nccl.git && \
    cd /tmp/nccl && \
    make -j4 && \
    make debian && \
    make deb && \
    sudo dpkg -i build/deb/*.deb && cd /tmp && rm -rf /tmp/nccl
#ADD libnccl1_1.3.2-1+cuda8.0_amd64.deb ./libnccl.deb
#ADD libnccl-dev_1.3.2-1+cuda8.0_amd64.deb ./libnccl-dev.deb
#RUN dpkg -i libnccl.deb libnccl-dev.deb

USER root
RUN apt-get install --no-install-recommends -y --force-yes build-essential cmake git gfortran libatlas-base-dev libboost-all-dev libgflags-dev libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libprotobuf-dev libsnappy-dev protobuf-compiler python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil python-pip python-protobuf python-scipy python-skimage python-sklearn && apt-get clean

# example location - can be customized
ENV CAFFE_ROOT=/usr/local/caffe-nv
RUN git clone https://github.com/NVIDIA/caffe.git $CAFFE_ROOT && \
    pip install -r $CAFFE_ROOT/python/requirements.txt
WORKDIR $CAFFE_ROOT
RUN mkdir build
WORKDIR ${CAFFE_ROOT}/build
RUN cmake -DUSE_NCCL=ON .. && make --jobs=4

RUN mkdir -p /db
RUN python /usr/share/digits/digits/download_data mnist /db/mnist
RUN python /usr/share/digits/digits/download_data cifar10 /db/cifar10
RUN python /usr/share/digits/digits/download_data cifar100 /db/cifar100
RUN chown -R nimbix:nimbix /db
RUN chown -R nimbix:nimbix /usr/share/digits


RUN apt-get install -y --force-yes nginx && apt-get clean
# Add our custom configuration
ADD ./conf/nginx.conf /etc/nginx/nginx.conf
ADD ./conf/digits.site /etc/nginx/sites-available/digits.site
RUN ln -sf /etc/nginx/sites-available/digits.site /etc/nginx/sites-enabled/digits.site
#ADD ./conf/httpredirect.conf /etc/nginx/conf.d/httpredirect.conf

# Add the JARVICE app-specific files
ADD ./NAE/url.txt /etc/NAE/url.txt
ADD ./NAE/help.html /etc/NAE/help.html
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./scripts /usr/local/scripts
ADD ./conf/digits.cfg /usr/share/digits/digits/digits.cfg

# Keep the digits logs in the standard place...append this to the output
RUN mkdir -p /var/log/digits && touch /var/log/digits/digits.log && chown -R nimbix:nimbix /var/log/digits && chown -R nimbix:nimbix /usr/local/scripts

RUN mkdir -p /usr/share/digits/digits
RUN ln -sf /data/DIGITS/jobs /usr/share/digits/digits/jobs

USER nimbix
CMD ["/usr/local/scripts/start.sh"]
