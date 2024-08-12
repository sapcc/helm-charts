ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
ARG BASE_IMG_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}-${BASE_IMG_VERSION} as builder
ARG SOFT_VERSION
ARG IMG_VERSION
ARG SOFT_NAME
ARG USERID
ARG MARIADB_VERSION
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV USERNAME=${SOFTWARE_NAME}
ENV USERID=${USERID}
ENV MARIADB_VERSION=${MARIADB_VERSION}
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

ADD http://www.haproxy.org/download/2.8/src/${SOFTWARE_NAME}-${SOFTWARE_VERSION}.tar.gz /tmp/

USER root
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

WORKDIR /tmp/
RUN apt-get update \
  && apt-get install -y build-essential libjemalloc-dev libevent-pthreads-2.1-7 libpcre2-dev libcrypt-dev libssl-dev zlib1g-dev liblua5.3-dev \
  && tar -xzf ${SOFTWARE_NAME}-${SOFTWARE_VERSION}.tar.gz

WORKDIR /tmp/${SOFTWARE_NAME}-${SOFTWARE_VERSION}
RUN make -j $(nproc) TARGET=linux-glibc USE_OPENSSL=1 USE_STATIC_PCRE2=1 USE_LIBCRYPT=1 USE_QUIC= USE_ZLIB=1 USE_LUA=1 USE_RT=1 USE_DL=1 ADDLIB=-ljemalloc -lpthread -lz

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
LABEL name=${SOFTWARE_NAME}
LABEL software.${SOFTWARE_NAME}=${SOFTWARE_NAME}
LABEL version.${SOFTWARE_NAME}.software=${SOFTWARE_VERSION}
LABEL version.${SOFTWARE_NAME}.image=${SOFTWARE_VERSION}-${IMAGE_VERSION}
LABEL maintainer.${SOFTWARE_NAME}.name="Birk Bohne"
LABEL maintainer.${SOFTWARE_NAME}.mail="birk.bohne@sap.com"
LABEL source_repository="https://github.com/sapcc/helm-charts/common/${SOFTWARE_NAME}-galera"

COPY --from=builder --chown=${USERID}:${USERID} /tmp/${SOFTWARE_NAME}-${SOFTWARE_VERSION}/${SOFTWARE_NAME} /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME}
COPY --chown=${USERID}:${USERID} --chmod=755 bin/*.sh /opt/${SOFTWARE_NAME}/bin/
COPY --chown=${USERID}:${USERID} --chmod=440 config/*.cfg /opt/${SOFTWARE_NAME}/etc/

USER root
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN apt-get update \
  && apt-get install -y --no-install-recommends liblua5.3-0 libssl1.1 libpcre2-8-0 libjemalloc2 libevent-2.1-7 libcrypt1 zlib1g \
  && apt-get -y autoclean \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd ${SOFTWARE_NAME} --gid ${USERID} \
  && adduser ${SOFTWARE_NAME} --home /opt/${SOFTWARE_NAME} --uid ${USERID} --gid ${USERID} --gecos "" --shell /sbin/nologin --no-create-home --disabled-login \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} -v | grep ${SOFTWARE_VERSION}

USER ${USERNAME}
WORKDIR /opt/${SOFTWARE_NAME}
ENTRYPOINT ["/bin/bash", "--login", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]