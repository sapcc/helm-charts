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

ADD https://github.com/sysown/${SOFTWARE_NAME}/releases/download/v${SOFTWARE_VERSION}/${SOFTWARE_NAME}_${SOFTWARE_VERSION}-ubuntu20_amd64.deb /tmp/
COPY bin/*.sh /tmp/
COPY config/proxysql.cfg /tmp/
COPY config/*.tpl /tmp/

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN mkdir -p /opt/${SOFTWARE_NAME}/{bin,etc/tpl,data,log,run,tmp} \
  && groupadd ${SOFTWARE_NAME} --gid ${USERID} \
  && adduser ${SOFTWARE_NAME} --home /opt/${SOFTWARE_NAME} --uid ${USERID} --gid ${USERID} --gecos "" --shell /sbin/nologin --no-create-home --disabled-login \
  && dpkg --install /tmp/${SOFTWARE_NAME}_${SOFTWARE_VERSION}-ubuntu20_amd64.deb \
  && apt-get update \
  && apt-get install --no-install-recommends -y mysql-client \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && rm -vf /tmp/${SOFTWARE_NAME}_${SOFTWARE_VERSION}-ubuntu20_amd64.deb \
  && mv -vf /tmp/*.sh /opt/${SOFTWARE_NAME}/bin \
  && mv -vf /tmp/proxysql.cfg /opt/${SOFTWARE_NAME}/etc/ \
  && mv -vf /tmp/*.tpl /opt/${SOFTWARE_NAME}/etc/tpl/ \
  && chown -Rv ${SOFTWARE_NAME}:${SOFTWARE_NAME} /opt/${SOFTWARE_NAME} \
  && chmod -v 755 /opt/${SOFTWARE_NAME}/bin/*.sh \
  && /usr/bin/${SOFTWARE_NAME} --version | grep -i "${SOFTWARE_NAME} version ${SOFTWARE_VERSION}"

USER ${SOFTWARE_NAME}
VOLUME ["/opt/${SOFTWARE_NAME}/data", "/opt/${SOFTWARE_NAME}/log"]
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]