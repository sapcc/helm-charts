FROM rabbitmq:3.12.6-management
LABEL appversion="3.12.6-management" \
      appname="rabbitmq" \
      apprelease="3.12.6-management" \
      appsummary='RabbitMQ 3.12.6-management' \
      maintainer='DL PlusOne CE_API_Core (External) <DL_5BEAD4A27809E00286A10FD4@global.corp.sap>' \
      baseOS="ubuntu22.04" \
      source_repository="https://github.com/sapcc/helm-charts/tree/master/common/rabbitmq/docker/ubuntu"

RUN set eux; \
    apt-get update; \
	  apt-get upgrade -y
