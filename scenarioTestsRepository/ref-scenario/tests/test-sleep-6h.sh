#!/bin/bash

set -euxo pipefail

INPUT_DIR=$2
ls $INPUT_DIR
cat $INPUT_DIR/deployment.properties

echo Sleeping for 6h
sleep 6h

echo 'Copying dummy surefire-reports to data bucket'
wget https://s3.amazonaws.com/testgrid-resources/test-dev-phase1/Dummy1.zip
mkdir -p ${OUTPUT_DIR}/scenarios
unzip -qo Dummy1.zip -d ${OUTPUT_DIR}/scenarios
rm Dummy1.zip

echo completed.
