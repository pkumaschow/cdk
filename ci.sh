#!/bin/bash
set -e

RUNTIME=docker
if [ "${1}" = "podman" ]; then
  RUNTIME=podman
fi

echo "Building cdk alpine ${RUNTIME} image"

if [ -z ${CI} ]; then
  ${RUNTIME} build -t cdk:latest .
else
  ${RUNTIME} build -t cdk:latest /godata/pipelines/docker-cdk/.
fi
