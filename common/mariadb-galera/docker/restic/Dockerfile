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
ENV USERNAME=${SOFTWARE_NAME}
ENV USERID=${USERID}
ENV XDG_CACHE_HOME=/opt/${SOFTWARE_NAME}/var/run
ENV TMPDIR=/opt/${SOFTWARE_NAME}/var/tmp
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

COPY --chown=${USERID}:${USERID} bin/*.sh /opt/${SOFTWARE_NAME}/bin/
ADD https://github.com/${SOFTWARE_NAME}/${SOFTWARE_NAME}/releases/download/v${SOFTWARE_VERSION}/${SOFTWARE_NAME}_${SOFTWARE_VERSION}_linux_amd64.bz2 /tmp/${SOFTWARE_NAME}_linux_amd64.bz2

USER root
WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN mkdir -p /opt/${SOFTWARE_NAME}/{bin,etc,var/run,var/tmp} \
  && groupadd ${SOFTWARE_NAME} --gid ${USERID} \
  && adduser ${SOFTWARE_NAME} --home /opt/${SOFTWARE_NAME} --uid ${USERID} --gid ${USERID} --gecos "" --shell /sbin/nologin --no-create-home --disabled-login \
  && echo 'export PATH=${PATH}:/opt/${SOFTWARE_NAME}/bin' > /opt/${SOFTWARE_NAME}/.bashrc \
  && bzip2 --decompress /tmp/${SOFTWARE_NAME}_linux_amd64.bz2 \
  && mv /tmp/${SOFTWARE_NAME}_linux_amd64 /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} \
  && rm -f /tmp/${SOFTWARE_NAME}_linux_amd64.bz2 \
  && chown -R ${USERNAME}:${USERNAME} /opt/${SOFTWARE_NAME} \
  && chmod 755 /opt/${SOFTWARE_NAME}/bin/* \
  && chmod -R 755 /opt/${SOFTWARE_NAME}/var/ \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} version | grep ${SOFTWARE_VERSION}

USER ${USERNAME}
WORKDIR /opt/${SOFTWARE_NAME}
ENTRYPOINT ["/bin/bash", "--login", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]