# Base
FROM ubuntu:14.04


###########################################################################
# Regular system stuff
###########################################################################

RUN apt-get -y update \
  && apt-get upgrade -y \
  && apt-get -y install git-core build-essential gfortran curl \
  && apt-get install -y --no-install-recommends software-properties-common


###########################################################################
# Install Java.
# From official Oracle Java 8 Dockerfile
###########################################################################

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get  update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle


###########################################################################
# Install good blas : OpenBlas
# From Olivier Grisel : https://github.com/ogrisel/docker-openblas
###########################################################################

ADD ./src/openblas/openblas.conf /etc/ld.so.conf.d/openblas.conf
ADD ./src/openblas/build_openblas.sh build_openblas.sh
RUN bash build_openblas.sh


###########################################################################
# Python Environment
###########################################################################

# Python 2.7
RUN apt-get -y update
RUN apt-get install -y \
  python2.7 \
  python2.7-dev \
  python-pip \
  python-setuptools

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
ADD ./py-requirement.txt py-requirement.txt
RUN pip install -r py-requirement.txt
# Download NLTK and Spacy model
RUN python -m nltk.downloader punkt
RUN python -m spacy.en.download --force all


###########################################################################
# Install Spark
# from https://github.com/gettyimages/docker-spark/blob/master/Dockerfile
###########################################################################

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

# ADD jars for S3 : aws-java-sdk-1.7.4.jar && 
RUN mkdir -p $SPARK_HOME/jars && cd $_ \
  && wget \
    "http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar" \
    "http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.1/hadoop-aws-2.7.1.jar"

# Add conf file
ADD ./src/spark/spark-default.conf $SPARK_HOME/conf/spark-default.conf


###########################################################################
# Clean and Reduce image size
###########################################################################

RUN apt-get autoremove -y
RUN apt-get clean -y

EXPOSE 4040
