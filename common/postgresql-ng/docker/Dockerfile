FROM debian:12-slim

# locale installation based on https://github.com/docker-library/postgres/blob/master/16/bookworm/Dockerfile#L49-L59 licensed under MIT

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get upgrade -y \
  # install locales which are excluded on dbeian slim variant by default \
  && grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker \
  && sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker \
  && ! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker \
  && apt-get install --no-install-recommends -y \
    # required for https \
    ca-certificates \
    # drop privilges easy
    gosu \
    # required utf-8 encoding \
    locales \
    # contains script to add apt.postgresql.org and pg_conftool \
    postgresql-common \
  && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
  && pg_conftool /etc/postgresql-common/createcluster.conf set create_main_cluster false \
  && apt-get install --no-install-recommends -y \
    postgresql-9.5 \
    postgresql-12 \
    postgresql-15 \
    postgresql-16 \
  && rm -rf /var/lib/apt/lists/* \
  && for conf in /usr/share/postgresql/*/postgresql.conf.sample; do \
    pg_conftool "$conf" set listen_addresses '*' ; \
  done \
  # generate locale and update it in case glibc was updated \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && mkdir -p /initdb.d /maintaindb.d /var/lib/postgresql

COPY ./entrypoint.sh /usr/local/bin/

ENV LANG en_US.utf8

ARG BININFO_BUILD_DATE BININFO_COMMIT_HASH BININFO_VERSION
LABEL source_repository="https://github.com/sapcc/helm-charts/blob/master/common/postgresql-ng/docker/Dockerfile" \
  org.opencontainers.image.url="https://github.com/sapcc/helm-charts/blob/master/common/postgresql-ng/docker/Dockerfile" \
  org.opencontainers.image.created=${BININFO_BUILD_DATE} \
  org.opencontainers.image.revision=${BININFO_COMMIT_HASH} \
  org.opencontainers.image.version=${BININFO_VERSION}

# dropped almost immeadetly by gosu
USER root
STOPSIGNAL SIGINT
ENTRYPOINT [ "entrypoint.sh" ]
