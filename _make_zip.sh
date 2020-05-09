#!/usr/bin/env bash

set -e

# AWS Lambda Layer Zip Builder for Python Libraries
#   This script is executed inside a docker container by the "build_layer.sh" script
#   It builds the zip file with files in lambda layers dir structure
#     /python/lib/pythonX.X/site-packages

scriptname=$(basename "$0")
scriptbuildnum="1.0.1"
scriptbuilddate="2020-05-08"

### VARS
CURRENT_DIR=$(reldir=$(dirname -- "$0"; echo x); reldir=${reldir%?x}; cd -- "$reldir" && pwd && echo x); CURRENT_DIR=${CURRENT_DIR%?x}

PYTHON="python${PYTHON_VER}"
ZIP_FILE="base_${PYTHON}.zip"

echo "BUILDING ZIP: ${ZIP_FILE} for ${PYTHON}"

# Create build dir
mkdir /tmp/build

# Create virtual environment and activate it
virtualenv -p $PYTHON /tmp/build
source /tmp/build/bin/activate

# Install requirements
pip install -r /temp/build/requirements.txt --no-cache-dir

# Create staging area in dir structure req for lambda layers
mkdir -p "/tmp/base/python/lib/${PYTHON}"

# Move dependancies to staging area
mv "/tmp/build/lib/${PYTHON}/site-packages" "/tmp/base/python/lib/${PYTHON}"

# remove unused libraries
cd "/tmp/base/python/lib/${PYTHON}/site-packages"
rm -rf easy-install*
rm -rf wheel*
rm -rf setuptools*
rm -rf virtualenv*
rm -rf pip*

# Delete .pyc files from staging area
cd "/tmp/base/python/lib/${PYTHON}"
find . -name '*.pyc' -delete

# Add files from staging area to zip
cd /tmp/base
zip -r "${CURRENT_DIR}/${ZIP_FILE}" .

echo -e "\nBASE ZIP CREATION FINISHED"
