ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
FROM ${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}
ARG IMG_VERSION
ENV SOFTWARE_NAME=${BASE_SOFT_NAME}
ENV SOFTWARE_VERSION=${BASE_SOFT_VERSION}
ENV IMAGE_VERSION=${IMG_VERSION}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN  apt-get update \
  && apt-get upgrade -y --no-install-recommends \
  && apt-get install -y --no-install-recommends \
  curl \
  dnsutils \
  gettext-base\
  iputils-ping \
  net-tools \
  unzip \
  sysstat \
  jq \
  ca-certificates \
  bzip2 \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/*
