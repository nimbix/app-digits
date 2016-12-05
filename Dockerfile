FROM jarvice/ubuntu-ibm-mldl-ppc64le
MAINTAINER Nimbix, Inc.

USER root
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install --no-install-recommends -y --force-yes git graphviz python-dev python-flask python-flaskext.wtf python-gevent python-h5py python-numpy python-pil python-pip python-protobuf python-scipy
RUN apt-get install -y --force-yes libpng12-0 libpng12-dev libfreetype6 libfreetype6-dev
RUN apt-get build-dep -y --force-yes python-matplotlib

WORKDIR /usr/share
RUN git clone https://github.com/NVIDIA/DIGITS.git digits
ENV DIGITS_ROOT=/usr/share/digits
WORKDIR ${DIGITS_ROOT}
RUN git checkout -b v5.0.0
RUN sudo pip install -r $DIGITS_ROOT/requirements.txt
RUN sudo pip install -e $DIGITS_ROOT

# # Access to CUDA packages (from https://github.com/NVIDIA/DIGITS/blob/digits-4.0/docs/UbuntuInstall.md#repository-access)
# ENV CUDA_REPO_PKG=cuda-repo-ubuntu1604_8.0.44-1_amd64.deb
# RUN wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG}
# RUN dpkg -i /tmp/${CUDA_REPO_PKG}
# RUN rm -f /tmp/${CUDA_REPO_PKG}
# RUN apt-get update

# Install Caffe
RUN apt-get install --no-install-recommends -y --force-yes build-essential cmake git gfortran libatlas-base-dev libboost-all-dev libgflags-dev libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libprotobuf-dev libsnappy-dev protobuf-compiler python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil python-pip python-protobuf python-scipy python-skimage python-sklearn

# example location - can be customized
ENV CAFFE_ROOT=/usr/local/caffe-nv
RUN git clone https://github.com/NVIDIA/caffe.git $CAFFE_ROOT
RUN pip install -r $CAFFE_ROOT/python/requirements.txt
WORKDIR $CAFFE_ROOT
RUN mkdir build
WORKDIR ${CAFFE_ROOT}/build
RUN cmake ..
RUN make --jobs=4

# Access to Machine Learning packages
#ENV ML_REPO_PKG=nvidia-machine-learning-repo-ubuntu1404_4.0-2_amd64.deb
#RUN wget http://developer.download.nvidia.com/compute/machine-learning/repos/u#bntu1404/x86_64/${ML_REPO_PKG} -O /tmp/${ML_REPO_PKG}
#RUN dpkg -i /tmp/${ML_REPO_PKG}
#RUN rm -f /tmp/${ML_REPO_PKG}

# Add the example data sets
RUN mkdir -p /db
RUN python /usr/share/digits/digits/download_data mnist /db/mnist
RUN python /usr/share/digits/digits/download_data cifar10 /db/cifar10
RUN python /usr/share/digits/digits/download_data cifar100 /db/cifar100
RUN chown -R nimbix:nimbix /db
RUN chown -R nimbix:nimbix /usr/share/digits


RUN apt-get install -y --force-yes nginx
# Add our custom configuration
ADD ./conf/nginx.conf /etc/nginx/nginx.conf
ADD ./conf/digits.site /etc/nginx/sites-available/digits.site
RUN ln -sf /etc/nginx/sites-available/digits.site /etc/nginx/sites-enabled/digits.site

# Add the JARVICE app-specific files
ADD ./NAE/url.txt /etc/NAE/url.txt
ADD ./NAE/help.html /etc/NAE/help.html
ADD ./scripts /usr/local/scripts
ADD ./conf/digits.cfg /usr/share/digits/digits/digits.cfg

# Keep the digits logs in the standard place...append this to the output
RUN mkdir -p /var/log/digits && touch /var/log/digits/digits.log && chown -R nimbix:nimbix /var/log/digits
RUN chown -R nimbix:nimbix /usr/local/scripts

RUN mkdir -p /usr/share/digits/digits
RUN ln -sf /data/DIGITS/jobs /usr/share/digits/digits/jobs

CMD ["/usr/local/scripts/start.sh"]

RUN apt-get install -y gunicorn
ADD ./JARVICE /etc/JARVICE
