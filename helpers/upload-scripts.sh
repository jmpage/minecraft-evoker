#!/bin/bash -x
DIRECTORY="$( dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))"
aws s3 mv ${DIRECTORY}/scripts/ s3://${BUCKET}/common/scripts --recursive
