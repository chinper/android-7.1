FROM ubuntu:bionic

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update -y
RUN apt-get install -y openjdk-8-jdk python3 git-core gnupg flex bison gperf build-essential \
    zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
    lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
    libgl1-mesa-dev libxml2-utils xsltproc unzip mtools u-boot-tools \
    htop iotop sysstat iftop pigz bc device-tree-compiler lunzip \
    dosfstools vim-common

# RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && \
#     chmod +x /usr/local/bin/repo

RUN curl -L https://github.com/aktau/github-release/releases/download/v0.6.2/linux-amd64-github-release.tar.bz2 | tar -C /tmp -jx && \
    mv /tmp/bin/linux/amd64/github-release /usr/local/bin/

RUN apt-get install -y repo

RUN apt-get install -y gradle locales git-lfs rsync

RUN which repo && \
    which github-release

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8

USER root
# Fix jack server SSL issue during build
RUN perl -0777 -i -p -e 's/(jdk.tls.disabledAlgorithms=.*?), TLSv1, TLSv1\.1/$1/g' \
     /etc/java-8-openjdk/security/java.security
