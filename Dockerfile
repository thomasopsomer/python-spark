# Base
FROM ubuntu:14.04

# System
RUN apt-get -y update \
  && apt-get -y install git-core build-essential gfortran \
  && apt-get install -y --no-install-recommends software-properties-common

# Install Java.
# From official Oracle Java 8 Dockerfile
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install git
RUN apt-get install -y git

# Install good blas : OpenBlas
# From Olivier Grisel : https://github.com/ogrisel/docker-openblas
ADD ./src/openblas/openblas.conf /etc/ld.so.conf.d/openblas.conf
ADD ./src/openblas/build_openblas.sh build_openblas.sh
RUN bash build_openblas.sh

# Install python
RUN apt-get install -y gcc
RUN apt-get install -y python2.7 python2.7-dev python-pip
RUN apt-get install -y python-setuptools

# Python packages
# Numpy Scipy scikit-learn
# From Olivier Grisel for good open blas action :)
# https://github.com/ogrisel/docker-sklearn-openblas
ADD ./src/numpy-scipy/numpy-site.cfg numpy-site.cfg
ADD ./src/numpy-scipy/scipy-site.cfg scipy-site.cfg
ADD ./src/numpy-scipy/build_sklearn.sh build_sklearn.sh
RUN bash build_sklearn.sh
# lxml
RUN apt-get install -y libxml2-dev libxslt1-dev \
  && apt-get install -y python-lxml
# Other via pip and requirements file
# add g++ for spacy
RUN apt-get install -y g++
ADD ./py-requirement.txt py-requirement.txt
RUN pip install -r py-requirement.txt

# curl
RUN apt-get install -y curl

# Install Spark
# from https://github.com/gettyimages/docker-spark/blob/master/Dockerfile
# SPARK
ENV SPARK_VERSION 1.5.2
ENV HADOOP_VERSION 2.6
ENV SPARK_PACKAGE $SPARK_VERSION-bin-hadoop$HADOOP_VERSION
ENV SPARK_HOME /usr/spark-$SPARK_PACKAGE
ENV PATH $PATH:$SPARK_HOME/bin
RUN curl -sL --retry 3 \
  "http://mirrors.ibiblio.org/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_PACKAGE.tgz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $SPARK_HOME /usr/spark


# Clean and Reduce image size
RUN apt-get autoremove -y
RUN apt-get clean -y


#
# # Define working directory.
# WORKDIR /data
#

#

#
# # Install scala
#
#
# # Install scikit learn
# ADD ./numpy-scipy/numpy-site.cfg numpy-site.cfg
# ADD ./numpy-scipy/scipy-site.cfg scipy-site.cfg
# ADD ./numpy-scipy/build_sklearn.sh build_sklearn.sh
# RUN bash build_sklearn.sh
#
#
# # Define default command.
# CMD ["bash"]
