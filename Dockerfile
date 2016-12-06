FROM jarvice/ubuntu-ibm-mldl-ppc64le
MAINTAINER Nimbix, Inc.

USER root
RUN apt-get update
RUN apt-get install -y git
RUN apt-get install --no-install-recommends -y --force-yes git graphviz python-dev python-flask python-flaskext.wtf python-gevent python-h5py python-numpy python-pil python-pip python-protobuf python-scipy
RUN apt-get install -y --force-yes libpng12-0 libpng12-dev libfreetype6 libfreetype6-dev
RUN apt-get build-dep -y --force-yes python-matplotlib

WORKDIR /usr/share
RUN git clone https://github.com/nimbix/DIGITS.git digits
ENV DIGITS_ROOT=/usr/share/digits
WORKDIR ${DIGITS_ROOT}
RUN git checkout digits-5.0-https
RUN sudo pip install -r $DIGITS_ROOT/requirements.txt
RUN sudo pip install -e $DIGITS_ROOT

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
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./scripts /usr/local/scripts
ADD ./conf/digits.cfg /usr/share/digits/digits/digits.cfg

# Keep the digits logs in the standard place...append this to the output
RUN mkdir -p /var/log/digits && \
    touch /var/log/digits/digits.log && \
    chown -R nimbix:nimbix /var/log/digits && \
    chown -R nimbix:nimbix /usr/local/scripts

USER nimbix
CMD ["/usr/local/scripts/start.sh"]
