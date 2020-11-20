#!/usr/bin/env bash

TOOLBOX_DOCKER_IMAGE=( {{ required ".Values.global.registry is missing" .Values.global.registry }}/ccloud/toolbox )
TOOLBOX_DOCKER_TAG=( {{ required ".Values.images.toolbox.tag is missing" .Values.images.toolbox.tag }} )
TOOLBOX_DIRECTORY=( {{ required ".Values.toolbox.toolboxDir is missing" .Values.toolbox.toolboxDir }} )
TOOLBOX_IMAGE_NAME=( {{ required ".Values.toolbox.toolboxName is missing" .Values.toolbox.toolboxName }} )
TOOLBOX_PATH="${TOOLBOX_DIRECTORY}/${TOOLBOX_IMAGE_NAME}"

if [ -d "${TOOLBOX_PATH}" ]; then rm -Rf ${TOOLBOX_PATH}; fi
mkdir -p "${TOOLBOX_PATH}"

docker run --name toolbox ${TOOLBOX_DOCKER_IMAGE}:${TOOLBOX_DOCKER_TAG}
docker export toolbox > toolbox.tar
tar xvf toolbox.tar -C "${TOOLBOX_PATH}"

echo "toolbox image ${TOOLBOX_DOCKER_IMAGE}:${TOOLBOX_DOCKER_TAG} exported to ${TOOLBOX_PATH} and is ready! "
