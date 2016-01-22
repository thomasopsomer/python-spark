#!/usr/bin/bash

# Build evertything and clean up build dependencies to have put everything in a
# single RUN step and workaround for:
# https://github.com/docker/docker/issues/332

set -xe

# Cython first
pip install cython

# Temporary build folder
mkdir /tmp/build
cd /tmp/build

# Build NumPy and SciPy from source against OpenBLAS installed
git clone -q git://github.com/numpy/numpy.git
cp /numpy-site.cfg numpy/site.cfg
(cd numpy && python setup.py install)

git clone -q git://github.com/scipy/scipy.git
cp /scipy-site.cfg scipy/site.cfg
(cd scipy && python setup.py install)

# Build scikit-learn against OpenBLAS as well, by introspecting the numpy
# runtime config.
pip install git+git://github.com/scikit-learn/scikit-learn.git

# Reduce the image size
# pip3 uninstall -y cython
# apt-get remove -y --purge git-core build-essential python-dev
# apt-get autoremove -y
# apt-get clean -y

cd /
rm -rf /tmp/build
rm -rf build_sklearn.sh