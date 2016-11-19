#!/bin/bash -x
DEFAULT_STACK_NAME=minecraft-stack
aws cloudformation delete-stack --stack-name ${STACK_NAME-DEFAULT_STACK_NAME}
