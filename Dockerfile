FROM ubuntu:vivid
MAINTAINER Tully Foote<tfoote@osrfoundation.org>


ENV DEBIAN_FRONTEND noninteractive
RUN echo deb http://archive.ubuntu.com/ubuntu trusty-updates main >> /etc/apt/sources.list
RUN echo deb http://archive.ubuntu.com/ubuntu trusty universe >> /etc/apt/sources.list
RUN echo deb http://archive.ubuntu.com/ubuntu trusty-updates universe >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -q -y curl net-tools python python-pip python-yaml build-essential
RUN apt-get install -q -y ruby-dev
RUN apt-get install -q -y nodejs

RUN make --version

RUN gem install jekyll jekyll-sitemap --no-rdoc --no-ri
RUN gem install pygments.rb

EXPOSE 4000
VOLUME /tmp/jekyll
WORKDIR /tmp/jekyll

CMD jekyll serve -w --baseurl='' -d /tmp/_site
