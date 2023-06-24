# Changelog

## v0.14.5 - 2023/06/24
* imageversion type set to integer to support Container image versions like `10.5.20-20230620163110`
* software versions bumped
  * Ubuntu packages timestamp `20230620163110`

## v0.14.4 - 2023/06/08
* antiaffinity rules for hosts & zones distribute MariaDB and ProxySQL pods across different availibility zones and hosts if possible
* [weighted Quorum](https://galeracluster.com/library/documentation/weighted-quorum.html#wq-three-nodes) as configurable option `mariadb.galera.weightedQuorum`
* software versions bumped
  * MariaDB [10.5.20](https://mariadb.com/kb/en/mariadb-10-5-20-release-notes/)
  * ProxySQL [2.5.2](https://github.com/sysown/proxysql/releases/tag/v2.5.2)
  * yq [4.33.3](https://github.com/mikefarah/yq/releases/tag/v4.33.3)

## v0.14.3 - 2023/05/19
* `mysqld_exporter` permissions setup fixed
* software versions bumped
  * Galera [26.4.14](https://fromdual.com/galera-cluster-release-notes#galera-plugin-26-4-14-release-notes)

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
