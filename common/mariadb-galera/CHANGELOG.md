# Changelog

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