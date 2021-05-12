#!/usr/bin/env bash

TOOLBOX_DOCKER_IMAGE=( {{ required ".Values.global.registry is missing" .Values.global.registry }}/toolbox )
TOOLBOX_DOCKER_TAG=( {{ required ".Values.images.toolbox.tag is missing" .Values.images.toolbox.tag }} )
TOOLBOX_DIRECTORY=( {{ required ".Values.toolbox.toolboxDir is missing" .Values.toolbox.toolboxDir }} )
TOOLBOX_IMAGE_NAME=( {{ required ".Values.toolbox.toolboxName is missing" .Values.toolbox.toolboxName }} )
TOOLBOX_PATH="${TOOLBOX_DIRECTORY}/${TOOLBOX_IMAGE_NAME}"

if [ -d "${TOOLBOX_PATH}" ]; then rm -Rf ${TOOLBOX_PATH}; fi
mkdir -p "${TOOLBOX_PATH}"

# Needed to trigger keppel replication
: <<'END_COMMENT'
image: "{{ required ".Values.global.registry is missing" .Values.global.registry }}/toolbox:{{ required ".Values.images.toolbox.tag is missing" .Values.images.toolbox.tag }}"
END_COMMENT

docker pull ${TOOLBOX_DOCKER_IMAGE}:${TOOLBOX_DOCKER_TAG}
docker run --name toolbox ${TOOLBOX_DOCKER_IMAGE}:${TOOLBOX_DOCKER_TAG}
docker export toolbox > toolbox.tar
docker rm toolbox
tar xf toolbox.tar -C "${TOOLBOX_PATH}"
ls -la ${TOOLBOX_PATH}

echo "toolbox image ${TOOLBOX_DOCKER_IMAGE}:${TOOLBOX_DOCKER_TAG} exported to ${TOOLBOX_PATH} and is ready! "
