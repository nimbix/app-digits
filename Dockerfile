FROM nvcr.io/nvidia/digits:17.02

WORKDIR /tmp
RUN git clone https://github.com/nimbix/image-common.git && image-common/install-nimbix-ubuntu-trusty.sh && rm -rf image-common
EXPOSE 22

RUN chown -R nimbix:nimbix /opt/digits
RUN mkdir -p /db
RUN python /opt/digits/digits/download_data mnist /db/mnist && chown -R nimbix:nimbix /db/mnist
RUN python /opt/digits/digits/download_data cifar10 /db/cifar10 && chown -R nimbix:nimbix /db/cifar10
RUN python /opt/digits/digits/download_data cifar100 /db/cifar100 && chown -R nimbix:nimbix /db/cifar100

RUN apt-get install -y --force-yes nginx && apt-get clean
# Add our custom configuration
ADD ./conf/nginx.conf /etc/nginx/nginx.conf
ADD ./conf/digits.site /etc/nginx/sites-available/digits.site
RUN ln -sf /etc/nginx/sites-available/digits.site /etc/nginx/sites-enabled/digits.site

# Add the JARVICE app-specific files
ADD ./NAE/url.txt /etc/NAE/url.txt
ADD ./NAE/help.html /etc/NAE/help.html
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./scripts /usr/local/scripts
ADD ./conf/digits.cfg /opt/digits/digits/digits.cfg

# Keep the digits logs in the standard place...append this to the output
RUN mkdir -p /var/log/digits && touch /var/log/digits/digits.log && chown -R nimbix:nimbix /var/log/digits && chown -R nimbix:nimbix /usr/local/scripts

RUN mkdir -p /opt/digits/digits
RUN ln -sf /data/DIGITS/jobs /opt/digits/digits/jobs

USER nimbix
CMD ["/usr/local/scripts/start.sh"]
