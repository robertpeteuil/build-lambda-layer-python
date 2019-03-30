#!/usr/bin/env bash

set -e

# AWS Lambda Layer Zip Builder for Python Libraries
#   requires: docker, _make.zip.sh, build_layer.sh (this script)
#     Launches docker container from lambci/lambda:build-pythonX.X image
#         where X.X is the python version (2.7, 3.6, 3.7) - defaults to 3.6
#     Executes build script "_make.zip.sh" within container to create zip
#         with libs specified in requirements.txt
#     Zip filename includes python version used in its creation

scriptname=$(basename "$0")
scriptbuildnum="1.0.0"
scriptbuilddate="2019-03-30"

# used to set destination of zip
SUBDIR_MODE=""

displayVer() {
  echo -e "${scriptname}  ver ${scriptbuildnum} - ${scriptbuilddate}"
}

usage() {
  [[ "$1" ]] && echo -e "AWS Lambda Layer Zip Builder for Python Libraries\n"
  echo -e "usage: ${scriptname} [-p PYTHON_VER] [-s] [-r REQUIREMENTS-DIR] [-h] [-v]"
  echo -e "     -p PYTHON_VER\t: Python version to use: 2.7, 3.6, 3.7 (default 3.6)"
  echo -e "     -h\t\t\t: help"
  echo -e "     -v\t\t\t: display ${scriptname} version"
}

while getopts ":p:hv" arg; do
  case "${arg}" in
    p)  PYTHON_VER=${OPTARG};;
    h)  usage; exit;;
    v)  displayVer; exit;;
    \?) echo -e "Error - Invalid option: $OPTARG"; usage; exit;;
    :)  echo "Error - $OPTARG requires an argument"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))

# default Python to 3.6 if not set by CLI params
PYTHON_VER="${PYTHON_VER:-3.6}"

CURRENT_DIR=$(reldir=$(dirname -- "$0"; echo x); reldir=${reldir%?x}; cd -- "$reldir" && pwd && echo x); CURRENT_DIR=${CURRENT_DIR%?x}
BASE_DIR=$(basename $CURRENT_DIR)
PARENT_DIR=${CURRENT_DIR%"${BASE_DIR}"}

# find location of requirements.txt
if [[ -f "${CURRENT_DIR}/requirements.txt" ]]; then
  REQ_PATH="${CURRENT_DIR}/requirements.txt"
  echo "reqs in base dir"
elif [[ -f "${PARENT_DIR}/requirements.txt" ]]; then
  REQ_PATH="${PARENT_DIR}/requirements.txt"
  SUBDIR_MODE="True"
  echo "reqs in parent"
elif [[ -f "${PARENT_DIR}/function/requirements.txt" ]]; then
  REQ_PATH="${PARENT_DIR}/function/requirements.txt"
  SUBDIR_MODE="True"
  echo "reqs in parent/function"
else
  echo "Unable to find requirements.txt"
  exit 1
fi

docker run --rm -e PYTHON_VER="$PYTHON_VER" -v "$CURRENT_DIR":/var/task -v "$REQ_PATH":/temp/build/requirements.txt "lambci/lambda:build-python${PYTHON_VER}" bash /var/task/_make_zip.sh

# Move ZIP to parent dir if SUBDIR_MODE set
if [[ "$SUBDIR_MODE" ]]; then
  ZIP_FILE="base_python${PYTHON_VER}.zip"
  # Make backup of zip if exists in parent dir
  if [[ -f "${PARENT_DIR}/${ZIP_FILE}" ]]; then
    mv "${PARENT_DIR}/${ZIP_FILE}" "${PARENT_DIR}/${ZIP_FILE}.bak"
  fi
  mv "${CURRENT_DIR}/${ZIP_FILE}" "${PARENT_DIR}"
fi
