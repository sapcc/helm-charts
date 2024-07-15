VERSION_EXPORTER=202404181135
all: build-exporter push-exporter

build-exporter:
	docker build -t keppel.eu-de-1.cloud.sap/ccloud/auditbeat-exporter:${VERSION_EXPORTER} -f ./Dockerfile.exporter --platform linux/amd64 .

push-exporter:
	docker push keppel.eu-de-1.cloud.sap/ccloud/auditbeat-exporter:${VERSION_EXPORTER}
