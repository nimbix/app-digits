FROM nimbix/ubuntu-cuda:trusty
MAINTAINER stephen.fox@nimbix.net

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# Access to CUDA packages (from https://github.com/NVIDIA/DIGITS/blob/digits-4.0/docs/UbuntuInstall.md#repository-access)
ENV CUDA_REPO_PKG=cuda-repo-ubuntu1404_7.5-18_amd64.deb
RUN wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG}
RUN dpkg -i /tmp/${CUDA_REPO_PKG}
RUN rm -f /tmp/${CUDA_REPO_PKG}

# Access to Machine Learning packages
ENV ML_REPO_PKG=nvidia-machine-learning-repo-ubuntu1404_4.0-2_amd64.deb                
RUN wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1404/x86_64/${ML_REPO_PKG} -O /tmp/${ML_REPO_PKG}
RUN dpkg -i /tmp/${ML_REPO_PKG}
RUN rm -f /tmp/${ML_REPO_PKG}

# Download new list of packages
RUN apt-get update && apt-get install -y digits && rm -rf /var/lib/apt/lists/*

# Add the example data sets
RUN mkdir -p /db
RUN /usr/share/digits/tools/download_data/main.py mnist /db/mnist
RUN /usr/share/digits/tools/download_data/main.py cifar10 /db/cifar10
RUN /usr/share/digits/tools/download_data/main.py cifar100 /db/cifar100
RUN chown -R nimbix:nimbix /db
RUN chown -R nimbix:nimbix /usr/share/digits

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

COPY ./NAE/screenshot.png /etc/NAE/screenshot.png

CMD ["/usr/local/scripts/start.sh"]
