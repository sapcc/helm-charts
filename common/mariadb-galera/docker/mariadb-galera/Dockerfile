ARG BASE_REGISTRY BASE_ACCOUNT BASE_SOFT_NAME BASE_SOFT_VERSION BASE_IMG_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}-${BASE_IMG_VERSION}
ARG BASE_REGISTRY BASE_ACCOUNT BASE_SOFT_NAME BASE_SOFT_VERSION SOFT_VERSION GALERA_VERSION GALERA_DEBUG IMG_VERSION SOFT_NAME YQ_VERSION

ENV \
  SOFTWARE_VERSION=${SOFT_VERSION} \
  SOFTWARE_NAME=${SOFT_NAME} \
  IMAGE_VERSION=${IMG_VERSION} \
  GALERA_VERSION=${GALERA_VERSION} \
  GALERA_DEBUG=${GALERA_DEBUG} \
  USERNAME=mysql \
  YQ_VERSION=${YQ_VERSION} \
  MYSQL_HOME=/opt/${SOFT_NAME}/etc \
  MYSQL_HOST=localhost \
  MYSQL_UNIX_PORT=/opt/${SOFT_NAME}/run/mariadbd.sock \
  MYSQL_PS1="[\u@\h:\p]>"

LABEL \
  org.opencontainers.image.title=${SOFTWARE_NAME} \
  org.opencontainers.image.authors="Birk Bohne, Bashar Alkhateeb" \
  org.opencontainers.image.url="https://github.com/sapcc/helm-charts/blob/master/common/mariadb-galera/docker/mariadb-galera/Dockerfile" \
  org.opencontainers.image.version="${SOFTWARE_VERSION}" \
  org.opencontainers.image.base.name="${BASE_SOFT_NAME}" \
  org.opencontainers.image.base.digest="${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}" \
  source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

ADD --chown=mysql:mysql --chmod=755 bin/*.sh /opt/${SOFTWARE_NAME}/bin/
ADD --chown=mysql:mysql --chmod=644 config/my.cnf /opt/${SOFTWARE_NAME}/etc/
ADD --chown=mysql:mysql --chmod=644 config/*.tpl /opt/${SOFTWARE_NAME}/etc/sql/
ADD --chown=mysql:mysql config/*.role.yaml /opt/${SOFTWARE_NAME}/etc/sql/
ADD --chown=root:root --chmod=664 https://mariadb.org/mariadb_release_signing_key.asc /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc
ADD --chown=root:root --chmod=775 https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN \
  oldIFS="${IFS}" \
  && IFS=". " softVerProps=($(echo ${SOFTWARE_VERSION})) \
  && IFS="${oldIFS}" \
  && softMinorVer="${softVerProps[0]}.${softVerProps[1]}" \
  && softMajorVer="1:${SOFTWARE_VERSION}" \
  && IFS="+ " softVerProps=($(echo ${softVerProps[2]})) \
  && IFS="${oldIFS}" \
  && softPatchVer="${softMinorVer}.${softVerProps[0]}" \
  && if [ "${GALERA_DEBUG}" = true ]; then export GALERA_EXT='-dbg'; else export GALERA_EXT=''; fi \
  && echo "deb https://mirror1.hs-esslingen.de/pub/Mirrors/mariadb/repo/${softMinorVer}/ubuntu focal main" >>/etc/apt/sources.list \
  && apt-get update \
  && apt-get install --no-install-recommends -y socat ${SOFTWARE_NAME}-server-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-server-core-${softMinorVer}=${softMajorVer} galera-4${GALERA_EXT}=${GALERA_VERSION} galera-arbitrator-4${GALERA_EXT}=${GALERA_VERSION} ${SOFTWARE_NAME}-client-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-client-core-${softMinorVer}=${softMajorVer} mariadb-backup=${softMajorVer} libmariadb3=${softMajorVer} mysql-common=${softMajorVer} ${SOFTWARE_NAME}-common=${softMajorVer} \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /opt/${SOFTWARE_NAME}/{bin,data,etc/conf.d,etc/sql,run,tmp} \
  && chown -R ${USERNAME}:${USERNAME} /opt/${SOFTWARE_NAME} \
  && chmod 755 /opt/${SOFTWARE_NAME}/etc/sql/ \
  && /usr/bin/${SOFTWARE_NAME} --version | grep ${softPatchVer} \
  && yq --version | grep ${YQ_VERSION}

VOLUME ["/opt/${SOFTWARE_NAME}/data"]
USER ${USERNAME}
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]