# Changelog

## v0.25.0 - 2024/04/24
* Add standardised Kubernetes labels accorting to:
  * [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels)
  * [Helm standard labels](https://helm.sh/docs/chart_best_practices/labels/#standard-labels)

## v0.24.0 - 2024/04/22
* multi region support for Galera added
  * MariaDB Galera cluster can be deployed in 3 regions
  * currently limited to one cluster node per region, will be extended in the future
  * WAN configuration tweaks added
  * helm unit tests added
  * [documentation](README.md#multi-region-support) added
* packages timestamp updated to `20240419150126`
* chart version bumped

## v0.23.1 - 2024/02/12
* helm unit tests for migration option added
* packages timestamp updated to `20240212072432`
* chart version bumped

## v0.23.0 - 2024/01/30
* helm unit tests added
* mariadb.migration.enabled chart option added
  * to support the migration from another MariaDB instance
* chart version bumped

## v0.22.3 - 2024/01/29
* packages timestamp updated to `20240129111302`
* chart version bumped

## v0.22.1 - 2023/11/17
* fixes from 0.20.4 added
  * Ubuntu packages timestamp `20231117111140`
  * `MARIADB_MONITORING` credential for ProxySQL fixed
* chart version bumped

## v0.22.0 - 2023/10/30
* linkerd [annotation support](https://linkerd.io/2.14/tasks/adding-your-service/#meshing-a-service-with-annotations) added
  *  for linkerd to inject the transport encryption sidecar container
* chart version bumped

## v0.21.0 - 2023/10/26
* NFS support for Kopia added
  * now S3 and NFS backends are supported
  * the [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) has to installed in the cluster
* chart version bumped

## v0.20.4 - 2023/10/18
* MariaDB service name aligned to the existing MariaDB single pod Helm chart
  * for easier migration
  * less changes required if used as a subchart dependency
* Ubuntu packages timestamp `20231117111140`
* `MARIADB_MONITORING` credential for ProxySQL fixed
* chart version bumped

## v0.20.3 - 2023/10/11
* label 'application' replaced with 'database' to be more specific about the different components
* chart version bumped

## v0.20.2 - 2023/10/10
* name prefix for K8s objects refactored
  * use the same function structure everywhere
  * no trailing '-' character
* monitoring user also made optional on Docker level
* mysql_exporter role renamed to monitor on Docker level too
* software versions bumped
  * Ubuntu packages timestamp `20231010194415`
* chart version bumped

## v0.20.1 - 2023/10/09
* `namePrefix.includeClusterName` parameter added to use the `mariadb.galera.clustername` as name prefix for all generated Kubernetes objects
  * disabled per default
* chart version bumped

## v0.20.0 - 2023/10/07
* `mariadb.users.monitor` user only mandatory if the mysqld_exporter or ProxySQL are enabled
  * redundant ProxySQL monitor user config removed
  * `MARIADB_MONITORING_USERNAME` environment variable check added for the mysqld_exporter container image
* software versions bumped
  * Ubuntu packages timestamp `20231009043336`
  * ProxySQL updated to version `2.5.5`
  * yq updated to `4.35.2`
* chart version bumped

## v0.19.0 - 2023/09/27
* Prometheus alert definitions added
  * MariaDB & Galera Cluster alerts added
  * Kubernetes alerts added
  * ProxySQL & Kopia alerts will follow
* chart version bumped

## v0.18.0 - 2023/09/13
* HAProxy as additional proxy option added
  * currently in alpha state
  * no readiness/liveness checks yet
  * no proper mysql health check yet
* chart version bumped

## v0.17.0 - 2023/07/21
* Restic backup option removed
  * Kopia is the only backup option now
* chart version bumped

## v0.16.0 - 2023/07/20
* Point in time recovery option added
  * documentation added
  * optional binary log file purging after full backup
    * to free up disk space on the `log` persistent volume
    * keep the binlog backups small and fast
  * binlog filename and position added to snapshot tags
  * binlog file size limited to 100MB
    * to limit the required disk space on the backup job container
* chart version bumped

## v0.15.4 - 2023/07/05
* proxysql Kubernetes secret names fixed
* chart version bumped

## v0.15.3 - 2023/07/03
* pull secret enablement fixed for the different components
* chart version bumped

## v0.15.2 - 2023/07/03
* support for [Kubernetes pull secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) added
* chart version bumped

## v0.15.1 - 2023/07/03
* mysqld_exporter config templating fixed
  * _USERNAME reverted back to _USER
* chart version bumped

## v0.15.0 - 2023/06/30
* credential support in values.yaml (to be used with external templating)
  * based on that the secrets.yaml will generate Kubernetes secrets
  * the related [environment variables will lookup the credential infos](https://kubernetes.io/docs/tasks/inject-data-database/distribute-credentials-secure/#define-container-environment-variables-using-secret-data) from the secrets
  * Credentials for the different components can be maintained (MariaDB, mysqld_exporter, ProxySQL, Kopia, Restic)
* database and roles management also moved into the values.yaml
* separate config folder structure for MariaDB credentials, roles and databases removed
* `CREATE USER IF NOT EXISTS` and `ALTER USER IF EXISTS` instead of `CREATE OR REPLACE USER` to avoid lockouts during MariaDB credential management
* software versions bumped
  * Ubuntu packages timestamp `20230629170110`

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
