#!/bin/bash
set -e

echo "Building cdk alpine docker image"

if [ -z ${CI}]; then
  docker build -t cdk:latest .
else
  docker build -t cdk:latest /godata/pipelines/docker-cdk/.
fi
