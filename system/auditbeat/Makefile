VERSION=7.17.12-amd64
VERSION_EXPORTER=202311291700
all: build push

build: build-auditbeat build-exporter

push: push-auditbeat push-exporter

build-auditbeat:
	docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/auditbeat-oss:${VERSION} --build-arg IMAGE=docker.elastic.co/beats/auditbeat-oss:${VERSION} .

push-auditbeat:
	docker push keppel.eu-de-1.cloud.sap/ccloud/auditbeat-oss:${VERSION}

build-exporter:
	docker build -t keppel.eu-de-1.cloud.sap/ccloud/auditbeat-exporter:${VERSION_EXPORTER} -f ./Dockerfile.exporter --platform linux/amd64 .

push-exporter:
  docker push keppel.eu-de-1.cloud.sap/ccloud/auditbeat-exporter:${VERSION_EXPORTER}
