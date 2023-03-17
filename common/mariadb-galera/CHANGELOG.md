# Changelog

## v0.14.2 - 2023/03/17
* galerastatus configmap missing name prefix fixed

## v0.14.1 - 2023/03/10
* old `MARIADB_CLUSTER_NAME` environment variable removed from the values.yaml

## v0.14.0 - 2023/03/10
* prefix for generated Kubernetes objects
  * `mariadb.galera.clustername` used for that
* `MARIADB_CLUSTER_NAME` environment variable also derived from `mariadb.galera.clustername`

## v0.13.0 - 2023/03/03
* Kopia as additional backup option
* configmaps restructured for better maintainability
* dedicated Docker images for the backup tools

## v0.11.3 - 2023/01/16
* `perf_schema` [collector options](https://github.com/prometheus/mysqld_exporter#collector-flags) for the MySQL exporter disabled if `$.Values.mariadb.performance_schema` chart option is disabled
* changelog added

## v0.11.4 - 2023/01/16
* software versions bumped
  * Ubuntu 22.04 as base image for ProxySQL and the MySQL Exporter
  * still Ubuntu 20.04 for the MariaDB Galera image because 22.04 is only supported for MariaDB 10.6 or newer
  * ProxySQL [2.4.6](https://github.com/sysown/proxysql/releases/tag/v2.4.6)
  * yq [4.30.8](https://github.com/mikefarah/yq/releases/tag/v4.30.8)
  * restic [0.15.0](https://github.com/restic/restic/releases/tag/v0.15.0)

## v0.11.5 - 2023/01/17
* mount [Kubernetes service account token](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting) only in the MariaDB pods
* TLS certificate secret name fixed for the backup, restore and config jobs
