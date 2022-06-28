ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
ARG BASE_IMG_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}-${BASE_IMG_VERSION}
ARG SOFT_VERSION
ARG GALERA_VERSION
ARG IMG_VERSION
ARG SOFT_NAME
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV GALERA_VERSION=${GALERA_VERSION}
ENV USERID=1234
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN oldIFS="${IFS}" \
  && IFS=". " softVerProps=($(echo ${SOFTWARE_VERSION})) \
  && IFS="${oldIFS}" \
  && softMinorVer="${softVerProps[0]}.${softVerProps[1]}" \
  && softMajorVer="1:${SOFTWARE_VERSION}+maria~focal" \
  && curl -s -L 'https://mariadb.org/mariadb_release_signing_key.asc' -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc \
  && echo "deb https://mirror1.hs-esslingen.de/pub/Mirrors/mariadb/repo/${softMinorVer}/ubuntu focal main" >>/etc/apt/sources.list \
  && apt-get update \
  && apt-get install --no-install-recommends -y ${SOFTWARE_NAME}-server-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-server-core-${softMinorVer}=${softMajorVer} galera-4=${GALERA_VERSION}-focal ${SOFTWARE_NAME}-client-${softMinorVer}=${softMajorVer} ${SOFTWARE_NAME}-client-core-${softMinorVer}=${softMajorVer} libmariadb3=${softMajorVer} mysql-common=${softMajorVer} ${SOFTWARE_NAME}-common=${softMajorVer} \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /opt/${SOFTWARE_NAME}/data \
  && groupadd ${SOFTWARE_NAME} --gid "${USERID}" \
  && adduser ${SOFTWARE_NAME} --home "/opt/${SOFTWARE_NAME}" --uid "${USERID}" --gid "${USERID}" --gecos "" --shell /sbin/nologin --no-create-home --disabled-login

COPY bin/entrypoint.sh /opt/${SOFTWARE_NAME}/bin/
RUN chown -R ${SOFTWARE_NAME}:${SOFTWARE_NAME} /opt/${SOFTWARE_NAME} \
  && chmod 755 /opt/${SOFTWARE_NAME}/bin/entrypoint.sh \
  && /usr/bin/${SOFTWARE_NAME} --version | grep ${SOFTWARE_VERSION}

VOLUME ["/opt/${SOFTWARE_NAME}/data"]
USER ${SOFTWARE_NAME}
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]