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
ENV SOFTWARE_VERSION=${SOFT_VERSION}
ENV SOFTWARE_NAME=${SOFT_NAME}
ENV USERNAME=${SOFTWARE_NAME}

ADD https://github.com/akopytov/${SOFTWARE_NAME}/archive/refs/tags/${SOFTWARE_VERSION}.tar.gz /tmp/

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

WORKDIR /tmp/
RUN apt-get update \
  && apt-get install -y --no-install-recommends make automake libtool pkg-config libaio-dev libmysqlclient-dev libssl-dev git libmysqlclient21 libaio1 \
  && tar -xzf ${SOFTWARE_VERSION}.tar.gz

WORKDIR /tmp/${SOFTWARE_NAME}-${SOFTWARE_VERSION}
RUN ./autogen.sh \
  && ./configure --prefix /opt/${SOFTWARE_NAME} \
  && make -j \
  && make install \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/bulk_insert.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_common.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_delete.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_insert.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_point_select.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_read_only.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_read_write.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_update_index.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/oltp_write_only.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/select_random_points.lua \
  && echo -e 'sysbench.hooks.report_intermediate = sysbench.report_default\nsysbench.hooks.report_cumulative = sysbench.report_json\n' >> /opt/${SOFTWARE_NAME}/share/sysbench/select_random_ranges.lua

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

COPY --from=builder --chown=${USERID}:${USERID} /opt/${SOFTWARE_NAME}/ /opt/${SOFTWARE_NAME}/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libmysqlclient.so.21 /usr/lib/x86_64-linux-gnu/libmysqlclient.so.21
COPY --from=builder /usr/lib/x86_64-linux-gnu/libaio.so.1 /usr/lib/x86_64-linux-gnu/libaio.so.1
COPY --chown=${USERID}:${USERID} --chmod=755 bin/*.sh /opt/${SOFTWARE_NAME}/bin/

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN groupadd ${SOFTWARE_NAME} --gid ${USERID} \
  && adduser ${SOFTWARE_NAME} --home /opt/${SOFTWARE_NAME} --uid ${USERID} --gid ${USERID} --gecos "" --shell /sbin/nologin --no-create-home --disabled-login \
  && /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --version | grep ${SOFTWARE_VERSION}

USER ${USERNAME}
WORKDIR /opt/${SOFTWARE_NAME}
ENTRYPOINT ["/bin/bash", "--login", "-c", "/opt/${SOFTWARE_NAME}/bin/entrypoint.sh"]