#!/bin/bash -x
DIRECTORY="$( dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))"
DEFAULT_STACK_NAME=minecraft-stack
aws cloudformation create-stack --stack-name ${STACK_NAME-DEFAULT_STACK_NAME} --template-body file://${DIRECTORY}/cfn/s3.template.json --parameters file://${DIRECTORY}/parameters.json --capabilities CAPABILITY_IAM
