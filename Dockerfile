# Base
FROM phusion/baseimage:0.9.15


###########################################################################
# Regular system stuff
###########################################################################
# deja in baseimage :
#   - software-properties-common
#   --no-install-recommends 
RUN apt-get -y update \
  && apt-get -y install git-core build-essential gfortran \
  && apt-get install -y --no-install-recommends software-properties-common \
  && apt-get install -y sqlite3


###########################################################################
# Install Java.
# From official Oracle Java 8 Dockerfile
###########################################################################

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get  update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle


# ###########################################################################
# # Install good blas : OpenBlas
# # From Olivier Grisel : https://github.com/ogrisel/docker-openblas
# ###########################################################################

ADD ./src/openblas/openblas.conf /etc/ld.so.conf.d/openblas.conf
ADD ./src/openblas/build_openblas.sh build_openblas.sh
RUN bash build_openblas.sh


# ###########################################################################
# # Python Environment
# ###########################################################################

# Python 2.7
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
RUN apt-get install -y \
  libxml2-dev \
  libxslt1-dev \
  python-lxml
# Other via pip and requirements file & Download NLTK and Spacy model
ADD ./py-requirement.txt py-requirement.txt
RUN pip install -r py-requirement.txt \
  && python -m nltk.downloader punkt \
  && python -m spacy.en.download --force all
  
# Luigi setup
RUN mkdir /etc/luigi /var/log/luigid /etc/service/luigid
ADD ./src/luigi/luigi.cfg /etc/luigi/client.cfg
ADD ./src/luigi/logrotate.cfg /etc/logrotate.d/luigid
ADD ./src/luigi/luigid.sh /etc/service/luigid/run
# VOLUME /var/log/luigid


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
RUN mkdir -p $SPARK_HOME/jars \
  && wget -P $SPARK_HOME/jars \
    "http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar" \
    "http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.1/hadoop-aws-2.7.1.jar" \
    "https://s3-us-west-2.amazonaws.com/ta-lib/directouputcommiter_2.10-1.0.jar"

# Add conf file
ADD ./src/spark/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf


###########################################################################
# Init Setup Script
###########################################################################

ADD init_script init_script
ENTRYPOINT ["./init_script"]


###########################################################################
# Clean and Reduce image size
###########################################################################

RUN apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  # && apt-get remove -y --purge build-essential python-dev

EXPOSE 4040
EXPOSE 8082
