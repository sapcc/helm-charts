ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
FROM debian:11 AS source
ARG SOFT_VERSION
ARG GALERA_VERSION
ARG IMG_VERSION
ARG SOFT_NAME
ARG YQ_VERSION
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV GALERA_VERSION=${GALERA_VERSION}
ENV YQ_VERSION=${YQ_VERSION}

COPY bin/*.sh /opt/${SOFTWARE_NAME}/bin/
COPY config/my.cnf /opt/${SOFTWARE_NAME}/etc/
COPY config/*.tpl /opt/${SOFTWARE_NAME}/etc/sql/
COPY config/*.role.yaml /opt/${SOFTWARE_NAME}/etc/sql/
ADD https://mirror1.hs-esslingen.de/pub/Mirrors/mariadb/mariadb-${SOFTWARE_VERSION}/bintar-linux-systemd-x86_64/mariadb-${SOFTWARE_VERSION}-linux-systemd-x86_64.tar.gz /tmp/
ADD https://archive.mariadb.org/mariadb-${SOFTWARE_VERSION}/galera-${GALERA_VERSION}/bintar/galera-${GALERA_VERSION}-x86_64.tar.gz /tmp/
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN tar -xzf /tmp/mariadb-${SOFTWARE_VERSION}-linux-systemd-x86_64.tar.gz --strip-components 1 --directory ${SOFTWARE_NAME}/ ${SOFTWARE_NAME}-${SOFTWARE_VERSION}-linux-systemd-x86_64/bin/ \
  && tar -xzf /tmp/mariadb-${SOFTWARE_VERSION}-linux-systemd-x86_64.tar.gz --strip-components 1 --directory ${SOFTWARE_NAME}/ ${SOFTWARE_NAME}-${SOFTWARE_VERSION}-linux-systemd-x86_64/lib/ \
  && tar -xzf /tmp/galera-${GALERA_VERSION}-x86_64.tar.gz --strip-components 2 --directory ${SOFTWARE_NAME}/ galera-26.4.14-x86_64/usr/bin/ \
  && tar -xzf /tmp/galera-${GALERA_VERSION}-x86_64.tar.gz --strip-components 3 --directory ${SOFTWARE_NAME}/lib/ galera-26.4.14-x86_64/usr/lib64/galera-4/ \
  && mkdir -p /opt/${SOFTWARE_NAME}/bin /opt/${SOFTWARE_NAME}/etc/conf.d /opt/${SOFTWARE_NAME}/etc/sql /opt/${SOFTWARE_NAME}/run /opt/${SOFTWARE_NAME}/tmp /opt/${SOFTWARE_NAME}/data /opt/${SOFTWARE_NAME}/log \
  && chown -R 65532:65532 /opt/${SOFTWARE_NAME} \
  && chmod 755 /opt/${SOFTWARE_NAME}/bin/*.sh \
  && chmod 644 /opt/${SOFTWARE_NAME}/etc/my.cnf \
  && chmod 755 /opt/${SOFTWARE_NAME}/etc/sql/ \
  && chmod -R 644 /opt/${SOFTWARE_NAME}/etc/sql/* \
  && chmod 755 /opt/${SOFTWARE_NAME}/data \
  && chmod 755 /opt/${SOFTWARE_NAME}/log \
  && chmod 755 /usr/local/bin/yq \
  && apt-get update \
  && apt-get install --no-install-recommends -y libncurses5 libtinfo5 socat gettext-base procps libcrypt1 libaio1 jq curl \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --version | grep ${SOFTWARE_VERSION} \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME}d --version | grep ${SOFTWARE_VERSION} \
  && yq --version | grep ${YQ_VERSION}

ARG BASE_REGISTRY
ARG BASE_ACCOUNT
ARG BASE_SOFT_NAME
ARG BASE_SOFT_VERSION
FROM ${BASE_REGISTRY}/${BASE_ACCOUNT}/${BASE_SOFT_NAME}:${BASE_SOFT_VERSION}
ARG SOFT_VERSION
ARG GALERA_VERSION
ARG IMG_VERSION
ARG SOFT_NAME
ARG YQ_VERSION
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV IMAGE_VERSION=${IMG_VERSION}
ENV GALERA_VERSION=${GALERA_VERSION}
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

COPY --from=source /bin/bash /bin/bash
COPY --from=source /bin/bash /bin/sh
COPY --from=source /usr/bin/env /usr/bin/env
COPY --from=source /bin/hostname /bin/hostname
COPY --from=source /bin/date /bin/date
COPY --from=source /bin/cat /bin/cat
COPY --from=source /bin/sleep /bin/sleep
COPY --from=source /bin/grep /bin/grep
COPY --from=source /lib/x86_64-linux-gnu/libpcre.so.3 /lib/x86_64-linux-gnu/libpcre.so.3
COPY --from=source /bin/ps /bin/ps
COPY --from=source /lib/x86_64-linux-gnu/libprocps.so.8 /lib/x86_64-linux-gnu/libprocps.so.8
COPY --from=source /usr/lib/x86_64-linux-gnu/libsystemd.so.0 /usr/lib/x86_64-linux-gnu/libsystemd.so.0
COPY --from=source /lib/x86_64-linux-gnu/liblzma.so.5 /lib/x86_64-linux-gnu/liblzma.so.5
COPY --from=source /usr/lib/x86_64-linux-gnu/libzstd.so.1 /usr/lib/x86_64-linux-gnu/libzstd.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/liblz4.so.1 /usr/lib/x86_64-linux-gnu/liblz4.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libgcrypt.so.20 /usr/lib/x86_64-linux-gnu/libgcrypt.so.20
COPY --from=source /lib/x86_64-linux-gnu/libgpg-error.so.0 /lib/x86_64-linux-gnu/libgpg-error.so.0
COPY --from=source /usr/bin/envsubst /usr/bin/envsubst
COPY --from=source /lib/x86_64-linux-gnu/libncurses.so.5 /lib/x86_64-linux-gnu/libncurses.so.5
COPY --from=source /lib/x86_64-linux-gnu/libtinfo.so.5 /lib/x86_64-linux-gnu/libtinfo.so.5
COPY --from=source /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.6
COPY --from=source /bin/sed /bin/sed
COPY --from=source /usr/lib/x86_64-linux-gnu/libacl.so.1 /usr/lib/x86_64-linux-gnu/libacl.so.1
COPY --from=source /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libselinux.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0
COPY --from=source /opt/${SOFTWARE_NAME} /opt/${SOFTWARE_NAME}
COPY --from=source /usr/local/bin/yq /usr/local/bin/yq
COPY --from=source /usr/bin/socat /usr/bin/socat
COPY --from=source /usr/lib/x86_64-linux-gnu/libwrap.so.0 /usr/lib/x86_64-linux-gnu/libwrap.so.0
COPY --from=source /usr/lib/x86_64-linux-gnu/libnsl.so.2 /usr/lib/x86_64-linux-gnu/libnsl.so.2
COPY --from=source /lib/x86_64-linux-gnu/libtirpc.so.3 /lib/x86_64-linux-gnu/libtirpc.so.3
COPY --from=source /lib/x86_64-linux-gnu/libcrypt.so.1 /lib/x86_64-linux-gnu/libcrypt.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libaio.so.1 /usr/lib/x86_64-linux-gnu/libaio.so.1
COPY --from=source /usr/bin/jq /usr/bin/jq
COPY --from=source /usr/lib/x86_64-linux-gnu/libjq.so.1 /usr/lib/x86_64-linux-gnu/libjq.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libonig.so.5 /usr/lib/x86_64-linux-gnu/libonig.so.5
COPY --from=source /usr/bin/curl /usr/bin/curl
COPY --from=source /usr/lib/x86_64-linux-gnu/libcurl.so.4 /usr/lib/x86_64-linux-gnu/libcurl.so.4
COPY --from=source /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libnghttp2.so.14 /usr/lib/x86_64-linux-gnu/libnghttp2.so.14
COPY --from=source /usr/lib/x86_64-linux-gnu/libidn2.so.0 /usr/lib/x86_64-linux-gnu/libidn2.so.0
COPY --from=source /usr/lib/x86_64-linux-gnu/librtmp.so.1 /usr/lib/x86_64-linux-gnu/librtmp.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libssh2.so.1 /usr/lib/x86_64-linux-gnu/libssh2.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libpsl.so.5 /usr/lib/x86_64-linux-gnu/libpsl.so.5
COPY --from=source /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.2 /usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2 /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/libbrotlidec.so.1 /usr/lib/x86_64-linux-gnu/libbrotlidec.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libunistring.so.2 /usr/lib/x86_64-linux-gnu/libunistring.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/libgnutls.so.30 /usr/lib/x86_64-linux-gnu/libgnutls.so.30
COPY --from=source /usr/lib/x86_64-linux-gnu/libhogweed.so.6 /usr/lib/x86_64-linux-gnu/libhogweed.so.6
COPY --from=source /usr/lib/x86_64-linux-gnu/libnettle.so.8 /usr/lib/x86_64-linux-gnu/libnettle.so.8
COPY --from=source /usr/lib/x86_64-linux-gnu/libgmp.so.10 /usr/lib/x86_64-linux-gnu/libgmp.so.10
COPY --from=source /usr/lib/x86_64-linux-gnu/libkrb5.so.3 /usr/lib/x86_64-linux-gnu/libkrb5.so.3
COPY --from=source /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 /usr/lib/x86_64-linux-gnu/libk5crypto.so.3
COPY --from=source /lib/x86_64-linux-gnu/libcom_err.so.2 /lib/x86_64-linux-gnu/libcom_err.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 /usr/lib/x86_64-linux-gnu/libkrb5support.so.0
COPY --from=source /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.2
COPY --from=source /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1 /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 /usr/lib/x86_64-linux-gnu/libp11-kit.so.0
COPY --from=source /usr/lib/x86_64-linux-gnu/libtasn1.so.6 /usr/lib/x86_64-linux-gnu/libtasn1.so.6
COPY --from=source /lib/x86_64-linux-gnu/libkeyutils.so.1 /lib/x86_64-linux-gnu/libkeyutils.so.1
COPY --from=source /usr/lib/x86_64-linux-gnu/libffi.so.7 /usr/lib/x86_64-linux-gnu/libffi.so.7
COPY --from=source /usr/bin/head /usr/bin/head
COPY --from=source /usr/bin/sort /usr/bin/sort

WORKDIR /opt
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
VOLUME ["/opt/${SOFTWARE_NAME}/data"]
USER nonroot
RUN /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --version \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME}d --version \
  && yq --version
ENTRYPOINT ["/bin/bash", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]