ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
ARG BASE_IMG_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}-${BASE_IMG_VERSION}
ARG SOFT_VERSION
ARG GALERA_VERSION
ARG GALERA_DEBUG
ARG IMG_VERSION
ARG SOFT_NAME
ARG YQ_VERSION
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV GALERA_VERSION=${GALERA_VERSION}
ENV GALERA_DEBUG=${GALERA_DEBUG}
ENV USERNAME=mysql
ENV YQ_VERSION=${YQ_VERSION}
ENV MYSQL_HOME=/opt/${SOFTWARE_NAME}/etc
ENV MYSQL_HOST=localhost
ENV MYSQL_UNIX_PORT=/opt/${SOFTWARE_NAME}/run/mariadbd.sock
ENV MYSQL_PS1="[\u@\h:\p]>"
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

COPY bin/*.sh /tmp/
COPY config/my.cnf /tmp/
COPY config/*.tpl /tmp/
COPY config/*.role.yaml /tmp/

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN oldIFS="${IFS}" \
  && IFS=". " softVerProps=($(echo ${SOFTWARE_VERSION})) \
  && IFS="${oldIFS}" \
  && softMinorVer="${softVerProps[0]}.${softVerProps[1]}" \
  && softMajorVer="1:${SOFTWARE_VERSION}" \
  && IFS="+ " softVerProps=($(echo ${softVerProps[2]})) \
  && IFS="${oldIFS}" \
  && softPatchVer="${softMinorVer}.${softVerProps[0]}" \
  && if [ "${GALERA_DEBUG}" = true ]; then export GALERA_EXT='-dbg'; else export GALERA_EXT=''; fi \
  && curl -s -L 'https://mariadb.org/mariadb_release_signing_key.asc' -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc \
  && echo "deb https://mirror1.hs-esslingen.de/pub/Mirrors/mariadb/repo/${softMinorVer}/ubuntu focal main" >>/etc/apt/sources.list \
  && apt-get update \
  && apt-get install --no-install-recommends -y socat ${SOFTWARE_NAME}-server-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-server-core-${softMinorVer}=${softMajorVer} galera-4${GALERA_EXT}=${GALERA_VERSION} galera-arbitrator-4${GALERA_EXT}=${GALERA_VERSION} ${SOFTWARE_NAME}-client-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-client-core-${softMinorVer}=${softMajorVer} mariadb-backup=${softMajorVer} libmariadb3=${softMajorVer} mysql-common=${softMajorVer} ${SOFTWARE_NAME}-common=${softMajorVer} \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && curl -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 -o /tmp/yq \
  && mv /tmp/yq /usr/local/bin/yq \
  && chmod 755 /usr/local/bin/yq \
  && mkdir -p /opt/${SOFTWARE_NAME}/{bin,data,etc/conf.d,etc/sql,run,tmp} \
  && mv /tmp/*.sh /opt/${SOFTWARE_NAME}/bin/ \
  && mv /tmp/my.cnf /opt/${SOFTWARE_NAME}/etc/ \
  && mv /tmp/*.tpl /opt/${SOFTWARE_NAME}/etc/sql/ \
  && mv /tmp/*.role.yaml /opt/${SOFTWARE_NAME}/etc/sql/ \
  && chown -R ${USERNAME}:${USERNAME} /opt/${SOFTWARE_NAME} \
  && chmod 755 /opt/${SOFTWARE_NAME}/bin/*.sh \
  && chmod 644 /opt/${SOFTWARE_NAME}/etc/my.cnf \
  && chmod -R 755 /opt/${SOFTWARE_NAME}/etc/sql/ \
  && chmod -R 644 /opt/${SOFTWARE_NAME}/etc/sql/* \
  && /usr/bin/${SOFTWARE_NAME} --version | grep ${softPatchVer} \
  && yq --version | grep ${YQ_VERSION}

VOLUME ["/opt/${SOFTWARE_NAME}/data"]
USER ${USERNAME}
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]