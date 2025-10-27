VERSION?=v0.15.2
REGISTRY?=quay.io
IMAGE?=keppel.eu-de-1.cloud.sap/ccloud

OPTS?=

all: build push

build:
	docker build ${OPTS} -t ${IMAGE}/cert-manager-controller:${VERSION} --build-arg IMAGE=${REGISTRY}/jetstack/cert-manager-controller:${VERSION} .
	docker build ${OPTS} -t ${IMAGE}/cert-manager-webhook:${VERSION} --build-arg IMAGE=${REGISTRY}/jetstack/cert-manager-webhook:${VERSION} .
	docker build ${OPTS} -t ${IMAGE}/cert-manager-cainjector:${VERSION} --build-arg IMAGE=${REGISTRY}/jetstack/cert-manager-cainjector:${VERSION} .

push:
	docker push ${IMAGE}/cert-manager-controller:${VERSION}
	docker push ${IMAGE}/cert-manager-webhook:${VERSION}
	docker push ${IMAGE}/cert-manager-cainjector:${VERSION}

.PHONY: all build push
