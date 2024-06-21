ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
ARG BASE_IMG_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}-${BASE_IMG_VERSION}
ARG SOFT_VERSION
ARG IMG_VERSION
ARG SOFT_NAME
ARG USERID
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV USERID=${USERID}
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

ADD https://github.com/prometheus/${SOFTWARE_NAME}/releases/download/v${SOFTWARE_VERSION}/${SOFTWARE_NAME}-${SOFTWARE_VERSION}.linux-amd64.tar.gz /tmp/
COPY bin/*.sh /tmp/

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN mkdir -p /opt/${SOFTWARE_NAME}/{bin,etc,run,tmp} \
  && groupadd ${SOFTWARE_NAME} --gid ${USERID} \
  && adduser ${SOFTWARE_NAME} --home /opt/${SOFTWARE_NAME} --uid ${USERID} --gid ${USERID} --gecos "" --shell /sbin/nologin --no-create-home --disabled-login \
  && tar -xvzf /tmp/${SOFTWARE_NAME}-${SOFTWARE_VERSION}.linux-amd64.tar.gz --strip-components 1 --directory ${SOFTWARE_NAME}/bin/ ${SOFTWARE_NAME}-${SOFTWARE_VERSION}.linux-amd64/${SOFTWARE_NAME} \
  && rm -fv /tmp/${SOFTWARE_NAME}-${SOFTWARE_VERSION}.linux-amd64.tar.gz \
  && mv -vf /tmp/*.sh /opt/${SOFTWARE_NAME}/bin \
  && chown -Rv ${SOFTWARE_NAME}:${SOFTWARE_NAME} /opt/${SOFTWARE_NAME} \
  && chmod -v 755 /opt/${SOFTWARE_NAME}/bin/*.sh /opt/${SOFTWARE_NAME}/bin/mysqld_exporter \
  #https://github.com/alecthomas/kingpin/issues/120 requires the redirect
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --version 2>&1 | grep "${SOFTWARE_NAME}, version ${SOFTWARE_VERSION}"

USER ${SOFTWARE_NAME}
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]