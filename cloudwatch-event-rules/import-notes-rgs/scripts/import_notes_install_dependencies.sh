#!/usr/bin/env bash

INSTALL_COMMAND="sudo pip install"
dependencies="numpy pandas requests requests_file boto3 botocore py4j slackclient"

sudo apt-get install python-pip
for dep in $dependencies; do
    $INSTALL_COMMAND $dep
done;