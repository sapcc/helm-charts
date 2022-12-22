# mariadb-galera

Docker images and Helm chart to deploy a [MariaDB](https://mariadb.com/kb/en/getting-installing-and-upgrading-mariadb/) HA cluster based on [Galera](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/)

## Table of Contents
* [Metadata](#Metadata)
* [Requirements](#Requirements)
* [Container images](#container-images)
  * [MariaDB Galera image](#mariadb-galera-image)
  * [MySQL Exporter image](#mysql-exporter-image)
  * [ProxySQL image](#proxysql-image)
* [Helm chart](#helm-chart)
  * [template](#template)
  * [install](#install)
  * [uninstall](#uninstall)
  * [values description](#values-description)
  * [network config](#network-config)
  * [database backup](#database-backup)
  * [full database restore](#full-database-restore)
  * [asynchronous replication config](#asynchronous-replication-config)
  * [MariaDB Galera flow charts](#mariadb-galera-flow-charts)
    * [node startup](#node-startup)
      * [container start](#container-start)
      * [init database](#init-database)
      * [init Galera](#init-galera)
      * [recover Galera](#recover-galera)
      * [bootstrap Galera](#bootstrap-galera)
* [additional documentation](#additional-documentation)
  * [Database](#database)
  * [Galera cluster](#galera-cluster)
  * [Primary/Replica replication](#primaryreplica-replication)
  * [Monitoring](#monitoring)
  * [Backup](#backup)

## Metadata
| chart version | app version | type | url |
|:--------------|:-------------|:-------------|:-------------|
| 0.11.1 | 10.5.18 | application | [Git repo](https://github.com/businessbean/helm-charts/tree/master/common/mariadb-galera) |

| Name | Email | Url |
| ---- | ------ | --- |
| Birk Bohne |  | <https://github.com/businessbean> |

## Requirements

Kubernetes: `>=1.18`

## Container images
### MariaDB Galera image
  | build argument | description |
  |:--------------|:-------------|
  | BASE_REGISTRY | hostname of the image registry |
  | BASE_ACCOUNT  | account/project used in the registry |
  | BASE_SOFT_NAME  | name of the software that will be used as base image |
  | BASE_SOFT_VERSION  | version of the software for the base image |
  | BASE_IMG_VERSION  | version of the base image |
  | SOFT_NAME  | name of the software that will be packaged into the image |
  | SOFT_VERSION  | version of the software that will be packaged into the image |
  | IMG_VERSION  | version of the image that will be build |
  | GALERA_VERSION  | Galera software version that should be packaged into the image |
  | GALERA_DEBUG  | install Galera debug packages |
  | YQ_VERSION | install this [yq version](https://github.com/mikefarah/yq/releases) |
  | RESTIC_VERSION | install this [restic version](https://github.com/restic/restic/releases) |

* productive version
  ```bash
  docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.74 --build-arg SOFT_NAME=mariadb --build-arg SOFT_VERSION=10.5.18+maria~ubu2004 --build-arg IMG_VERSION=0.3.2 --build-arg GALERA_VERSION=26.4.13-focal --build-arg YQ_VERSION=4.30.6 --build-arg RESTIC_VERSION=0.14.0 -t keppel.eu-de-1.cloud.sap/ccloud/mariadb-galera:10.5.18-0.3.2 -f docker/mariadb-galera/Dockerfile ./docker/mariadb-galera/
  ```
* debug version
  ```bash
  docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.74 --build-arg SOFT_NAME=mariadb --build-arg SOFT_VERSION=10.5.18+maria~ubu2004 --build-arg IMG_VERSION=0.3.2 --build-arg GALERA_VERSION=26.4.13-focal --build-arg YQ_VERSION=4.30.6 --build-arg RESTIC_VERSION=0.14.0 --build-arg GALERA_DEBUG=true -t keppel.eu-de-1.cloud.sap/ccloud/mariadb-galera-debug:10.5.18-0.3.2 -f docker/mariadb-galera/Dockerfile ./docker/mariadb-galera/
  ```

### MySQL Exporter image
| build argument | description |
|:--------------|:-------------|
| USERID | id of the user that should run the binary |

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.67 --build-arg SOFT_NAME=mysqld_exporter --build-arg SOFT_VERSION=0.14.0 --build-arg IMG_VERSION=0.1.1 --build-arg USERID=3000 -t keppel.eu-de-1.cloud.sap/ccloud/mysqld_exporter:0.14.0-0.1.1 -f docker/mysqld_exporter/Dockerfile ./docker/mysqld_exporter/
```

### ProxySQL image
| build argument | description |
|:--------------|:-------------|
| USERID | id of the user that should run the binary |

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.74 --build-arg SOFT_NAME=proxysql --build-arg SOFT_VERSION=2.4.5 --build-arg IMG_VERSION=0.1.3 --build-arg USERID=3100 -t keppel.eu-de-1.cloud.sap/ccloud/proxysql:2.4.5-0.1.3 -f docker/proxysql/Dockerfile ./docker/proxysql/
```

## Helm chart
### template
* render the chart templates
  ```shell
  helm template mariadb-galera helm --namespace database
  ```

### install
* deploy the chart using only the default values.yaml:
  ```shell
  helm upgrade --install --create-namespace --namespace database mariadb-galera helm
  ```

* with [additional custom values](https://helm.sh/docs/chart_template_guide/values_files/#helm) for a certain instance:
  ```shell
  helm upgrade --install --create-namespace --namespace database mariadb-galera helm --values helm/custom/eu-de-2.yaml
  ```

### uninstall
* remove the deployed release
  ```shell
  helm uninstall --namespace database mariadb-galera
  ```

### values description
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cleanOsCacheAtStartup | bool | `false` | only useful for benchmarking [www.kernel.org drop_caches](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html?highlight=drop_caches#drop-caches) |
| env.GALERA_SST_PASSWORD.containerType | list | `["application","jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.GALERA_SST_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `MariaDB Galera state snapshot transfer user` |
| env.GALERA_SST_PASSWORD.secretName | string | `"ga-sync-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `MariaDB Galera state snapshot transfer user` |
| env.GALERA_SST_USER.containerType | list | `["application","jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.GALERA_SST_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `MariaDB Galera state snapshot transfer user` |
| env.GALERA_SST_USER.secretName | string | `"ga-sync-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `MariaDB Galera state snapshot transfer user` |
| env.MARIADB_CLUSTER_NAME.containerType | list | `["application","cronjob"]` | for which containers this environment variable will be used |
| env.MARIADB_CLUSTER_NAME.value | string | `"eu-de-1.nova"` | Name of the MariaDB Galera cluster defined with the [wsrep_cluster_name](https://mariadb.com/kb/en/galera-cluster-system-variables/#wsrep_cluster_name) option |
| env.MARIADB_MONITORING_CONNECTION_LIMIT.containerType | list | `["application","jobconfig"]` | for which containers this environment variable will be used |
| env.MARIADB_MONITORING_CONNECTION_LIMIT.value | int | `6` | maximum number of allowed parallel connections for the `MariaDB monitoring user` defined within the [MAX_USER_CONNECTIONS](https://mariadb.com/kb/en/create-user/#resource-limit-options) option |
| env.MARIADB_MONITORING_PASSWORD.containerType | list | `["application","monitoring","jobconfig"]` | for which containers this environment variable will be used |
| env.MARIADB_MONITORING_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `MariaDB monitoring user` |
| env.MARIADB_MONITORING_PASSWORD.secretName | string | `"db-mon-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `MariaDB monitoring user` |
| env.MARIADB_MONITORING_USER.containerType | list | `["application","monitoring","jobconfig"]` | for which containers this environment variable will be used |
| env.MARIADB_MONITORING_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `MariaDB monitoring user` |
| env.MARIADB_MONITORING_USER.secretName | string | `"db-mon-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `MariaDB monitoring user` |
| env.MARIADB_ROOT_PASSWORD.containerType | list | `["application","jobconfig","jobrestore","proxy","cronjob"]` | for which containers this environment variable will be used |
| env.MARIADB_ROOT_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `MariaDB root user` |
| env.MARIADB_ROOT_PASSWORD.secretName | string | `"db-full-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `MariaDB root user` |
| env.MARIADB_ROOT_USER.containerType | list | `["application","jobconfig","jobrestore","proxy","cronjob"]` | for which containers this environment variable will be used |
| env.MARIADB_ROOT_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `MariaDB root user` |
| env.MARIADB_ROOT_USER.secretName | string | `"db-full-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `MariaDB root user` |
| env.OPENSTACK_CITEST_PASSWORD.containerType | list | `["jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.OPENSTACK_CITEST_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `Openstack oslo.db unit test user` |
| env.OPENSTACK_CITEST_PASSWORD.secretName | string | `"db-oslodb-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `Openstack oslo.db unit test user` |
| env.OPENSTACK_CITEST_USERNAME.containerType | list | `["jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.OPENSTACK_CITEST_USERNAME.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `Openstack oslo.db unit test user` |
| env.OPENSTACK_CITEST_USERNAME.secretName | string | `"db-oslodb-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `Openstack oslo.db unit test user` |
| env.OS_PASSWORD.containerType | list | `["cronjob","jobrestore"]` | for which containers this environment variable will be used |
| env.OS_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `Openstack swift user for restic` |
| env.OS_PASSWORD.secretName | string | `"restic-swift-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `Openstack swift user for restic` |
| env.OS_USERNAME.containerType | list | `["cronjob","jobrestore"]` | for which containers this environment variable will be used |
| env.OS_USERNAME.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `Openstack swift user for restic` |
| env.OS_USERNAME.secretName | string | `"restic-swift-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `Openstack swift user for restic` |
| env.PROXYSQL_ADMIN_PASSWORD.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_ADMIN_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `ProxySQL admin user` |
| env.PROXYSQL_ADMIN_PASSWORD.secretName | string | `"proxy-full-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `ProxySQL admin user` |
| env.PROXYSQL_ADMIN_USER.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_ADMIN_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `ProxySQL admin user` |
| env.PROXYSQL_ADMIN_USER.secretName | string | `"proxy-full-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `ProxySQL admin user` |
| env.PROXYSQL_MONITOR_PASSWORD.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_MONITOR_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `ProxySQL monitoring user for MariaDB` |
| env.PROXYSQL_MONITOR_PASSWORD.secretName | string | `"db-mon-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `ProxySQL monitoring user for MariaDB` |
| env.PROXYSQL_MONITOR_USER.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_MONITOR_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `ProxySQL monitoring user for MariaDB` |
| env.PROXYSQL_MONITOR_USER.secretName | string | `"db-mon-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `ProxySQL monitoring user for MariaDB` |
| env.PROXYSQL_STATS_PASSWORD.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_STATS_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `ProxySQL statistics user` |
| env.PROXYSQL_STATS_PASSWORD.secretName | string | `"proxy-stats-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `ProxySQL statistics user` |
| env.PROXYSQL_STATS_USER.containerType | list | `["proxy"]` | for which containers this environment variable will be used |
| env.PROXYSQL_STATS_USER.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `ProxySQL statistics user` |
| env.PROXYSQL_STATS_USER.secretName | string | `"proxy-stats-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `ProxySQL statistics user` |
| env.REPLICA_PASSWORD.containerType | list | `["application","jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.REPLICA_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `MariaDB async replication user` |
| env.REPLICA_PASSWORD.secretName | string | `"replica-primary-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `MariaDB async replication user` |
| env.REPLICA_USERNAME.containerType | list | `["application","jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.REPLICA_USERNAME.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `MariaDB async replication user` |
| env.REPLICA_USERNAME.secretName | string | `"replica-primary-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `MariaDB async replication user` |
| env.RESTIC_PASSWORD.containerType | list | `["cronjob","jobrestore"]` | for which containers this environment variable will be used |
| env.RESTIC_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `Restic repository encryption key` |
| env.RESTIC_PASSWORD.secretName | string | `"restic-repo-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `Restic repository encryption key` |
| env.SYSBENCH_PASSWORD.containerType | list | `["jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.SYSBENCH_PASSWORD.secretKey | string | `"password"` | Name of the key of the predefined Kubernetes secret that contains the `password` for the `sysbench user` |
| env.SYSBENCH_PASSWORD.secretName | string | `"db-sysbench-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `password` of the `sysbench user` |
| env.SYSBENCH_USERNAME.containerType | list | `["jobconfig","proxy"]` | for which containers this environment variable will be used |
| env.SYSBENCH_USERNAME.secretKey | string | `"username"` | Name of the key of the predefined Kubernetes secret that contains the `username` for the `sysbench user` |
| env.SYSBENCH_USERNAME.secretName | string | `"db-sysbench-auth"` | Name of the predefined [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables) that contains the key for the `username` of the `sysbench user` |
| env.WEB_TELEMETRY_PATH.containerType | list | `["monitoring"]` | for which containers this environment variable will be used |
| env.WEB_TELEMETRY_PATH.value | string | `"/metrics"` | The MySQL exporter monitoring sidecar container will expose the [Prometheus metrics](https://github.com/prometheus/mysqld_exporter#general-flags) under that path |
| groupId.application | string | 101 | run the MariaDB containers with that [group id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| groupId.monitoring | string | 3000 | run the MariaDB monitoring containers with that [group id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| groupId.proxy | string | 3100 | run the ProxySQL containers with that [group id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| hpa.application.enabled | bool | false | enable [horizontal pod autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) for the MariaDB Galera pods. Currently not suggested because even replica numbers cannot be avoided |
| hpa.application.maxCpuPercent | int | 66 | average CPU usage in percent across all MariaDB Galera pods that triggers the scaling process |
| hpa.application.maxReplicas | int | 5 | maximum number of replicas allowed for the MariaDB Galera pods |
| hpa.application.minReplicas | int | 3 | minimum number of replicas allowed for the MariaDB Galera pods |
| hpa.proxy.enabled | bool | false | enable [horizontal pod autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) for the ProxySQL cluster pods. Currently not suggested because even replica numbers cannot be avoided |
| hpa.proxy.maxCpuPercent | int | 66 | average CPU usage in percent across all ProxySQL cluster pods that triggers the scaling process |
| hpa.proxy.maxReplicas | int | 5 | maximum number of replicas allowed for the ProxySQL cluster pods |
| hpa.proxy.minReplicas | int | 3 | minimum number of replicas allowed for the ProxySQL cluster pods |
| image.application.applicationname | string | `"mariadb-galera"` | folder/container used in the image registry and also part of the image name |
| image.application.applicationversion | string | `"10.5.18"` | application part of the image version that should be pulled |
| image.application.imageversion | string | `"0.3.2"` | image part of the image version that should be pulled |
| image.application.project | string | `"ccloud"` | project/tenant used in the image registry |
| image.application.pullPolicy | string | IfNotPresent | `Always` to enforce that the image will be pulled even if it is already available on the worker node |
| image.application.pullSecret | string | `nil` | name of the already defined Kubernetes secret that should be used for registry authentication |
| image.application.registry | string | `"keppel.eu-de-1.cloud.sap"` | hostname of the image registry used to pull the application image that contains `MariaDB`, `Galera` and the two helpers `yq` and `restic` |
| image.monitoring.applicationname | string | `"mysqld_exporter"` | folder/container used in the image registry and also part of the image name |
| image.monitoring.applicationversion | string | `"0.14.0"` | application part of the image version that should be pulled |
| image.monitoring.imageversion | string | `"0.1.1"` | image part of the image version that should be pulled |
| image.monitoring.project | string | `"ccloud"` | project/tenant used in the image registry |
| image.monitoring.pullPolicy | string | IfNotPresent | `Always` to enforce that the image will be pulled even if it is already available on the worker node |
| image.monitoring.pullSecret | string | `nil` | name of the already defined Kubernetes secret that should be used for registry authentication |
| image.monitoring.registry | string | `"keppel.eu-de-1.cloud.sap"` | hostname of the image registry used to pull the monitoring image that currently contains the MySQL exporter for Prometheus |
| image.os.applicationname | string | `"ubuntu"` | folder/container used in the image registry and also part of the image name |
| image.os.applicationversion | float | `20.04` | application part of the image version that should be pulled |
| image.os.imageversion | string | `"0.3.74"` | image part of the image version that should be pulled |
| image.os.project | string | `"octobus"` | project/tenant used in the image registry |
| image.os.pullPolicy | string | IfNotPresent | `Always` to enforce that the image will be pulled even if it is already available on the worker node |
| image.os.pullSecret | string | `nil` | name of the already defined Kubernetes secret that should be used for registry authentication |
| image.os.registry | string | `"keppel.eu-nl-1.cloud.sap"` | hostname of the image registry used to pull the basic OS image that will be used for certain init steps |
| image.proxy.applicationname | string | `"proxysql"` | folder/container used in the image registry and also part of the image name |
| image.proxy.applicationversion | string | `"2.4.5"` | application part of the image version that should be pulled |
| image.proxy.imageversion | string | `"0.1.3"` | image part of the image version that should be pulled |
| image.proxy.project | string | `"ccloud"` | project/tenant used in the image registry |
| image.proxy.pullPolicy | string | IfNotPresent | `Always` to enforce that the image will be pulled even if it is already available on the worker node |
| image.proxy.pullSecret | string | `nil` | name of the already defined Kubernetes secret that should be used for registry authentication |
| image.proxy.registry | string | `"keppel.eu-de-1.cloud.sap"` | hostname of the image registry used to pull the proxy image that contains the ProxySQL software to load balance MariaDB connections |
| initContainers.cleanoscache.securityContext.privileged | bool | true | required to configure `/proc/sys/vm/drop_caches` in the init phase |
| initContainers.cleanoscache.securityContext.runAsUser | int | 0 | required to configure `/proc/sys/vm/drop_caches` in the init phase |
| initContainers.increaseMapCount.securityContext.privileged | bool | true | required to configure `/proc/sys/vm/max_map_count` in the init phase |
| initContainers.increaseMapCount.securityContext.runAsUser | int | 0 | required to configure `/proc/sys/vm/max_map_count` in the init phase |
| initContainers.tcpKeepAlive.securityContext.privileged | bool | true | required to configure `net.ipv4.tcp_keepalive_time` in the init phase |
| initContainers.tcpKeepAlive.securityContext.runAsUser | int | 0 | required to configure `net.ipv4.tcp_keepalive_time` in the init phase |
| job.mariadbbackup.concurrencyPolicy | string | Forbid | Define if and how MariaDB backup jobs can run in [parallel](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#concurrency-policy) |
| job.mariadbbackup.failedJobsHistoryLimit | int | 1 | Define how how many failed MariaDB backup jobs [should be kept](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#jobs-history-limits) |
| job.mariadbbackup.jobRestartPolicy | string | OnFailure | Define how the MariaDB backup job pod [will be restarted](https://kubernetes.io/docs/concepts/workloads/controllers/job/#handling-pod-and-container-failures) in case of an error. It can be on the same worker node or another |
| job.mariadbbackup.schedule | string | 05 23 * * * | [Schedule](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#schedule) for the MariaDB backup job based on that [syntax](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax) |
| job.mariadbbackup.successfulJobsHistoryLimit | int | 1 | Define how how many completed MariaDB backup jobs [should be kept](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#jobs-history-limits) |
| job.mariadbconfig.activeDeadlineSeconds | int | 300 | Maximum [allowed runtime](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup) before the MariaDB config job will be stopped |
| job.mariadbconfig.backoffLimit | int | 6 | How many [retries](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy) before the MariaDB config job will be marked as failed |
| job.mariadbconfig.jobRestartPolicy | string | OnFailure | Define how the MariaDB config job pod [will be restarted](https://kubernetes.io/docs/concepts/workloads/controllers/job/#handling-pod-and-container-failures) in case of an error. It can be on the same worker node or another |
| job.mariadbconfig.ttlSecondsAfterFinished | int | 120 | After how many seconds will a stopped MariaDB config job be [deleted from the Kubernetes cluster](https://kubernetes.io/docs/concepts/workloads/controllers/job/#clean-up-finished-jobs-automatically) |
| job.mariadbrestore.activeDeadlineSeconds | int | 3600 | Maximum [allowed runtime](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup) before the MariaDB restore job will be stopped |
| job.mariadbrestore.backoffLimit | int | 0 | How many [retries](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy) before the MariaDB restore job will be marked as failed |
| job.mariadbrestore.jobRestartPolicy | string | Never | Define how the MariaDB restore job pod [will be restarted](https://kubernetes.io/docs/concepts/workloads/controllers/job/#handling-pod-and-container-failures) in case of an error. It can be on the same worker node or another |
| job.mariadbrestore.ttlSecondsAfterFinished | int | 43200 | After how many seconds will a stopped MariaDB restore job be [deleted from the Kubernetes cluster](https://kubernetes.io/docs/concepts/workloads/controllers/job/#clean-up-finished-jobs-automatically) |
| livenessProbe.failureThreshold.application | int | 4 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the liveness probe for the MariaDB Galera pods is marked as failed |
| livenessProbe.failureThreshold.monitoring | int | 4 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the liveness probe for the MariaDB monitoring sidecar container is marked as failed |
| livenessProbe.failureThreshold.proxy | int | 4 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the liveness probe for the ProxySQL cluster pods is marked as failed |
| livenessProbe.initialDelaySeconds.application | int | 60 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for MariaDB Galera pods |
| livenessProbe.initialDelaySeconds.monitoring | int | 5 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for MariaDB monitoring sidecar container |
| livenessProbe.initialDelaySeconds.proxy | int | 60 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for ProxySQL cluster pods |
| livenessProbe.periodSeconds.application | int | 30 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for MariaDB Galera pods |
| livenessProbe.periodSeconds.monitoring | int | 30 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for MariaDB monitoring sidecar container |
| livenessProbe.periodSeconds.proxy | int | 30 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the liveness probe for ProxySQL cluster pods |
| livenessProbe.timeoutSeconds.application | int | 20 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the liveness probe for the MariaDB Galera pods |
| livenessProbe.timeoutSeconds.monitoring | int | 20 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the liveness probe for the MariaDB monitoring sidecar container |
| livenessProbe.timeoutSeconds.proxy | int | 20 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the liveness probe for the ProxySQL cluster pods |
| mariadb.asyncReplication.autostart | bool | false | start configured slave during database node startup [wsrep_restart_slave](https://mariadb.com/kb/en/galera-cluster-system-variables/#wsrep_restart_slave) |
| mariadb.asyncReplication.enabled | bool | false | to enable the [asynchronous replication config](#asynchronous-replication-config). Should be done within custom instance configuration files |
| mariadb.asyncReplication.primaryHost | bool | `false` | #Hostname or IP of the replication source [master_host](https://mariadb.com/kb/en/change-master-to/#master_host) |
| mariadb.asyncReplication.resetConfig | bool | `false` | reset the replica configuration. Use with care, because the currently used GTID binlog position value will be deleted. That can cause missing or duplicate data on the replica later |
| mariadb.asyncReplication.slaveReplicaThreads | int | 1 | how many [slave_parallel_threads](https://mariadb.com/kb/en/replication-and-binary-log-system-variables/#slave_parallel_threads) should be used for async replication |
| mariadb.autostart | bool | `true` | run the default entrypoint.sh script or just sleep to be able to troubleshoot and debug |
| mariadb.binLogDir | string | `"log"` | if not defined the data dir will be used. Needs a log volume mount to be configured too |
| mariadb.binLogSync | int | 0 | `1` to enable [sync_binlog for ACID compliance](https://mariadb.com/kb/en/replication-and-binary-log-system-variables/#sync_binlog) |
| mariadb.errorLogWarningVerbosity | int | 2 | to define the [verbosity](https://mariadb.com/kb/en/error-log/#configuring-the-error-log-verbosity) of the MariaDB logs |
| mariadb.galera.backup.enabled | bool | `false` | enable the [database backup](#database-backup). Should be done within custom instance configuration files |
| mariadb.galera.backup.openstack.authurl | string | `"https://openstack.keystone.url:443/v3"` | Openstack Keystone [url](https://docs.openstack.org/python-openstackclient/zed/cli/authentication.html) |
| mariadb.galera.backup.openstack.container | string | `nil` | Openstack [Swift](https://docs.openstack.org/swift/latest/) container |
| mariadb.galera.backup.openstack.projectname | string | `nil` | Openstack Keystone [project](https://docs.openstack.org/python-openstackclient/zed/cli/authentication.html) |
| mariadb.galera.backup.openstack.region | string | `nil` | Openstack Keystone [region](https://docs.openstack.org/python-openstackclient/zed/cli/authentication.html) |
| mariadb.galera.backup.openstack.tenantname | string | `nil` | Openstack Keystone [tenant](https://docs.openstack.org/python-openstackclient/zed/cli/authentication.html) |
| mariadb.galera.backup.restic.compression | string | auto | [compression](https://restic.readthedocs.io/en/stable/047_tuning_backup_parameters.html#compression) |
| mariadb.galera.backup.restic.keep.daily | int | 1 | [keep-daily](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.keep.hourly | int | 24 | [keep-hourly](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.keep.last | int | 2 | [keep-last](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.keep.monthly | int | 0 | [keep-monthly](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.keep.weekly | int | 0 | [keep-weekly](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.keep.yearly | int | 0 | [keep-yearly](https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy) |
| mariadb.galera.backup.restic.packsizeInMB | int | 16 | [pack-size](https://restic.readthedocs.io/en/stable/047_tuning_backup_parameters.html#pack-size) keep in mind the 5GB Swift object size limit and the potential object count quota limit |
| mariadb.galera.backup.restic.progressFps | float | 0.01666 | update interval for the console output [RESTIC_PROGRESS_FPS](https://restic.readthedocs.io/en/stable/040_backup.html?highlight=RESTIC_PROGRESS_FPS#environment-variables) |
| mariadb.galera.backup.restic.pruneBackups | bool | false | [removing backup snapshots](https://restic.readthedocs.io/en/stable/060_forget.html?highlight=prune#removing-backup-snapshots) |
| mariadb.galera.backup.restic.unlockRepo | bool | false | [unlock repo](https://restic.readthedocs.io/en/stable/manual_rest.html?highlight=unlock) |
| mariadb.galera.debug | bool | false | [Galera debug](https://galeracluster.com/library/documentation/galera-parameters.html#debug) |
| mariadb.galera.gcache.recover | bool | false | `false` until [PR#624](https://github.com/codership/galera/issues/624) is fixed |
| mariadb.galera.gtidDomainId | int | 1 | must be a positive integer [wsrep_gtid_domain_id](https://mariadb.com/kb/en/galera-cluster-system-variables/#wsrep_gtid_domain_id) |
| mariadb.galera.gtidDomainIdCount | int | 1 | how many Galera cluster instances will be connected. Used for [asynchronous replication](#asynchronous-replication-config) setups. Maximum of `2` is supported |
| mariadb.galera.gtidStrictMode | bool | false | enable [gtid_strict_mode](https://mariadb.com/kb/en/gtid/#gtid_strict_mode) |
| mariadb.galera.logLevel | string | info | [wsrep_debug](https://mariadb.com/kb/en/galera-cluster-system-variables/#wsrep_debug) |
| mariadb.galera.pcrecovery | bool | false | [primary component recovery](https://galeracluster.com/library/documentation/pc-recovery.html) |
| mariadb.galera.restore.beforeTimestamp | string | `nil` | define the backup timestamp that should be used for the restore. Only the `%Y-%m-%d %H:%M:%S` format is currently supported and the restic snapshot nearest before will be used |
| mariadb.galera.restore.enabled | bool | `false` | enable the [full database restore](#full-database-restore). Should be done as described in the documentation with `--set` parameters |
| mariadb.galera.restore.restic.progressFps | float | 0.01666 | update interval for the console output [RESTIC_PROGRESS_FPS](https://restic.readthedocs.io/en/stable/040_backup.html?highlight=RESTIC_PROGRESS_FPS#environment-variables) |
| mariadb.galera.restore.restic.snapshotId | bool | `false` | If set the beforeTimestamp option will be ignored and the configured id will be used |
| mariadb.galera.slaveThreads | int | 4 | [wsrep-slave-threads](https://galeracluster.com/library/documentation/mysql-wsrep-options.html#wsrep-slave-threads) |
| mariadb.galera.sst_method | string | `"rsync"` | `rsync` or `mariabackup` (also requires GALERA_SST_USER and GALERA_SST_PASSWORD) |
| mariadb.galera.waitForPrimaryTimeoutInSeconds | int | 30 | [pc.wait_prim_timeout](https://galeracluster.com/library/documentation/galera-parameters.html#pc.wait_prim_timeout) |
| mariadb.innodbFlushLogAtTrxCommit | int | 0 | `1` to enable [innodb_flush_log_at_trx_commit for ACID compliance](https://mariadb.com/kb/en/innodb-system-variables/#innodb_flush_log_at_trx_commit) |
| mariadb.performance_schema | bool | false | to enable the [Performance Schema](https://mariadb.com/kb/en/performance-schema-overview/) |
| mariadb.wipeDataAndLog | bool | false | will trigger a pod restart and remove all content from the data and log dir. This option will cause data loss and should only be used before triggering a [full database restore](#full-database-restore) |
| maxUnavailable.application | int | 1 | number of MariaDB pods that can be [unavailable](https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget) during a rolling upgrade |
| maxUnavailable.proxy | int | 1 | number of ProxySQL pods that can be [unavailable](https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget) during a rolling upgrade |
| monitoring.elasticBeatsAutoDiscoveryAnnotations.enabled | not yet implemented | `false` | add annotations to allow [automatic configuration](https://www.elastic.co/guide/en/beats/metricbeat/current/configuration-autodiscover-hints.html) of Elastic Beats agents |
| monitoring.mysqld_exporter.autostart | bool | `true` | run the default entrypoint.sh script or just sleep to be able to troubleshoot and debug |
| monitoring.mysqld_exporter.enabled | bool | false | enable the [Prometheus MySQL exporter](https://github.com/prometheus/mysqld_exporter) as sidecar container |
| monitoring.mysqld_exporter.metricsPort | int | 9104 | TCP port used by the exporter to listen for Prometheus connections |
| monitoring.prometheus.instance | string | prometheus | name of the Prometheus instance that should pull metrics |
| namePrefix.application | bool | `false` | name prefix used for the MariaDB pods, services etc. @default mariadb-g |
| namePrefix.proxy | bool | `false` | name prefix used for the ProxySQL pods, services etc. @default proxysql |
| podManagementPolicy | string | OrderedReady | [Pod Management Policy](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#pod-management-policies) for the MariaDB Galera and ProxySQL cluster pods. |
| proxy.adminui.enabled | bool | `true` | the [ProxySQL Admin UI](https://proxysql.com/documentation/http-web-server/) |
| proxy.adminui.verbosity | int | `0` | the variable defines the [verbosity level](https://proxysql.com/documentation/global-variables/admin-variables/#admin-web_verbosity) of the web server |
| proxy.enabled | bool | `false` | use ProxySQL in front of the MariaDB Galera pods to reduce the service downtimes for the clients |
| proxy.queryRules.genericReadWriteSplit.enabled | bool | `true` | check the "Generic Read/Write split using regex" section in the [howto](https://proxysql.com/documentation/proxysql-read-write-split-howto/) for details |
| proxy.restapi.enabled | bool | `true` | the [ProxySQL RestAPI](https://proxysql.com/documentation/REST-API/) |
| readinessProbe.failureThreshold.application | int | 2 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the readiness probe for the MariaDB Galera pods is marked as failed |
| readinessProbe.failureThreshold.monitoring | int | 2 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the readiness probe for the MariaDB monitoring sidecar container is marked as failed |
| readinessProbe.failureThreshold.proxy | int | 2 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the readiness probe for the ProxySQL cluster pods is marked as failed |
| readinessProbe.initialDelaySeconds.application | int | 90 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for MariaDB Galera pods |
| readinessProbe.initialDelaySeconds.monitoring | int | 10 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for MariaDB monitoring sidecar container |
| readinessProbe.initialDelaySeconds.proxy | int | 90 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for ProxySQL cluster pods |
| readinessProbe.periodSeconds.application | int | 20 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for MariaDB Galera pods |
| readinessProbe.periodSeconds.monitoring | int | 20 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for MariaDB monitoring sidecar container |
| readinessProbe.periodSeconds.proxy | int | 20 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the readiness probe for ProxySQL cluster pods |
| readinessProbe.successThreshold.application | int | 1 | After [how many](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) checks the readiness probe for the MariaDB Galera pods will be marked as successful |
| readinessProbe.successThreshold.monitoring | int | 1 | After [how many](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) checks the readiness probe for the MariaDB monitoring sidecar container will be marked as successful |
| readinessProbe.successThreshold.proxy | int | 1 | After [how many](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) checks the readiness probe for the ProxySQL cluster pods will be marked as successful |
| readinessProbe.timeoutSeconds.application | int | 10 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the readiness probe for the MariaDB Galera pods |
| readinessProbe.timeoutSeconds.monitoring | int | 10 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the readiness probe for the MariaDB monitoring sidecar container |
| readinessProbe.timeoutSeconds.proxy | int | 10 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the readiness probe for the ProxySQL cluster pods |
| regional | bool | `false` | If enabled `topology.kubernetes.io/zone` infos will be added to the [podAntiAffinity rules](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) for the MariaDB Galera and ProxySQL cluster. This is useful if the Kubernetes provider supports regional node pools to ensure a good pod distribution within that region |
| replicas.application | int | 3 | amount of pods that will [scheduled](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment) for the MariaDB Galera cluster. An uneven number will be enforced to avoid simple split brain situations. For a good balance between the write and read performance not more than 3 pods a suggested |
| replicas.proxy | int | 3 | amount of pods that will [scheduled](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment) for the ProxySQL cluster. An uneven number will be enforced to avoid simple split brain situations |
| resourceLimits.cpu.application | int | 0.5 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB containers |
| resourceLimits.cpu.cronjob | int | 0.25 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB backup cronjob |
| resourceLimits.cpu.jobconfig | float | 0.25 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB configuration job |
| resourceLimits.cpu.jobrestore | float | 0.25 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB restore job |
| resourceLimits.cpu.monitoring | float | 0.25 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the Monitoring sidecar containers for MariaDB |
| resourceLimits.cpu.proxy | int | 0.5 | CPU [resource reservation(request)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the ProxySQL containers |
| resourceLimits.memory.application | string | 64Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB containers |
| resourceLimits.memory.cronjob | string | 32Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB backup cronjob |
| resourceLimits.memory.jobconfig | string | 32Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB configuration job |
| resourceLimits.memory.jobrestore | string | 128Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the MariaDB restore job |
| resourceLimits.memory.monitoring | string | 32Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the Monitoring sidecar containers for MariaDB |
| resourceLimits.memory.proxy | string | 64Mi | RAM [resource limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for the ProxySQL containers |
| revisionHistoryLimit | int | 10 | how many [versions](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#clean-up-policy) of the rolled out statefulsets for the MariaDB Galera and ProxySQL cluster pods should be kept |
| scripts.logLevel | string | info | Log level of shell scripts used in the Helm chart. Can be `info` or `debug` |
| scripts.maxAllowedTimeDifferenceFactor | int | 3 | to multiply with `readinessProbe.timeoutSeconds.application` as the maximum allowed time difference between nodes for the last sequence number configmap update |
| scripts.maxRetries | int | 10 | how many times should script functions retry before failing |
| scripts.useTimeDifferenceForSeqnoCheck | bool | `false` | fail if time difference between nodes for the last sequence number configmap update is too big |
| scripts.waitTimeBetweenRetriesInSeconds | int | 6 | how long should script functions wait between retries |
| services.application.backend.headless | bool | `true` | `false` or `true` if the IP adresses of the pods that are [endpoints for that service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) should be advertised. Required to let the client make it's own load balancing decisions |
| services.application.backend.ports.galera.port | int | `4567` | exposed Galera [replication port](https://mariadb.com/kb/en/configuring-mariadb-galera-cluster/#network-ports) |
| services.application.backend.ports.galera.protocol | string | `"TCP"` | Galera [replication port](https://mariadb.com/kb/en/configuring-mariadb-galera-cluster/#network-ports) protocol |
| services.application.backend.ports.galera.targetPort | int | `4567` | Galera [replication port](https://mariadb.com/kb/en/configuring-mariadb-galera-cluster/#network-ports) configured in the container |
| services.application.backend.ports.ist.port | int | `4568` | exposed Galera [incremental state transfer port](http://galeracluster.com/library/documentation/galera-parameters.html#ist-recv-addr) |
| services.application.backend.ports.ist.protocol | string | `"TCP"` | Galera [incremental state transfer port](http://galeracluster.com/library/documentation/galera-parameters.html#ist-recv-addr) protocol |
| services.application.backend.ports.ist.targetPort | int | `4568` | Galera [incremental state transfer port](http://galeracluster.com/library/documentation/galera-parameters.html#ist-recv-addr) configured in the container |
| services.application.backend.ports.sst.port | int | `4444` | exposed Galera [state snapshot transfer port](https://mariadb.com/kb/en/introduction-to-state-snapshot-transfers-ssts/) |
| services.application.backend.ports.sst.protocol | string | `"TCP"` | Galera [state snapshot transfer port](https://mariadb.com/kb/en/introduction-to-state-snapshot-transfers-ssts/) protocol |
| services.application.backend.ports.sst.targetPort | int | `4444` | Galera [state snapshot transfer port](https://mariadb.com/kb/en/introduction-to-state-snapshot-transfers-ssts/) configured in the container |
| services.application.backend.sessionAffinity.type | string | `"None"` | `None` or `ClientIP` if connections from a single client should be [routed to the same endpoint](https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity) every time. |
| services.application.backend.type | string | `"ClusterIP"` | `ClusterIP` to configure a Kubernetes internal service or `LoadBalancer` to publish the service outside of the [Kubernetes cluster network](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| services.application.frontend.headless | bool | `false` | `false` or `true` if the IP adresses of the pods that are [endpoints for that service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) should be advertised. Required to let the client make it's own load balancing decisions |
| services.application.frontend.ports.mysql.port | int | `3306` | exposed MariaDB [SQL port](https://mariadb.com/kb/en/connecting-to-mariadb/#port) |
| services.application.frontend.ports.mysql.protocol | string | `"TCP"` | MariaDB [SQL port](https://mariadb.com/kb/en/connecting-to-mariadb/#port) protocol |
| services.application.frontend.ports.mysql.targetPort | int | `3306` | MariaDB [SQL port](https://mariadb.com/kb/en/connecting-to-mariadb/#port) configured in the container |
| services.application.frontend.sessionAffinity.ClientIpTimeoutSeconds | int | 10800 | [Session stickiness timeout](https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity) for the `sessionAffinity` option |
| services.application.frontend.sessionAffinity.type | string | `"ClientIP"` | `None` or `ClientIP` if connections from a single client should be [routed to the same endpoint](https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity) every time. |
| services.application.frontend.type | string | `"ClusterIP"` | `ClusterIP` to configure a Kubernetes internal service or `LoadBalancer` to publish the service outside of the [Kubernetes cluster network](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| services.proxy.backend.headless | bool | `true` | `false` or `true` if the IP adresses of the pods that are [endpoints for that service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) should be advertised. Required to let the client make it's own load balancing decisions |
| services.proxy.backend.ports.adminui.port | int | `6080` | exposed ProxySQL [Admin UI port](https://proxysql.com/documentation/http-web-server/) |
| services.proxy.backend.ports.adminui.protocol | string | `"TCP"` | ProxySQL [Admin UI port](https://proxysql.com/documentation/http-web-server/) protocol |
| services.proxy.backend.ports.adminui.targetPort | int | `6080` | ProxySQL [Admin UI port](https://proxysql.com/documentation/http-web-server/) configured in the container |
| services.proxy.backend.ports.proxy.port | int | `6032` | exposed ProxySQL [Admin SQL port](https://proxysql.com/Documentation/global-variables/admin-variables/#admin-mysql_ifaces) |
| services.proxy.backend.ports.proxy.protocol | string | `"TCP"` | ProxySQL [Admin SQL port](https://proxysql.com/Documentation/global-variables/admin-variables/#admin-mysql_ifaces) protocol |
| services.proxy.backend.ports.proxy.targetPort | int | `6032` | ProxySQL [Admin SQL port](https://proxysql.com/Documentation/global-variables/admin-variables/#admin-mysql_ifaces) configured in the container |
| services.proxy.backend.ports.restapi.port | int | `6070` | exposed ProxySQL [Rest API port](https://proxysql.com/documentation/REST-API/) |
| services.proxy.backend.ports.restapi.protocol | string | `"TCP"` | ProxySQL [Rest API port](https://proxysql.com/documentation/REST-API/) protocol |
| services.proxy.backend.ports.restapi.targetPort | int | `6070` | ProxySQL [Rest API port](https://proxysql.com/documentation/REST-API/) configured in the container |
| services.proxy.backend.sessionAffinity.type | string | `"None"` | `None` or `ClientIP` if connections from a single client should be [routed to the same endpoint](https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity) every time. |
| services.proxy.backend.type | string | `"ClusterIP"` | `ClusterIP` to configure a Kubernetes internal service or `LoadBalancer` to publish the service outside of the [Kubernetes cluster network](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| services.proxy.frontend.headless | bool | `false` | `false` or `true` if the IP adresses of the pods that are [endpoints for that service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) should be advertised. Required to let the client make it's own load balancing decisions |
| services.proxy.frontend.ports.proxy.port | int | `3306` | exposed ProxySQL [SQL port](https://proxysql.com/Documentation/global-variables/mysql-variables/#mysql-interfaces) |
| services.proxy.frontend.ports.proxy.protocol | string | `"TCP"` | ProxySQL [SQL port](https://proxysql.com/Documentation/global-variables/mysql-variables/#mysql-interfaces) protocol |
| services.proxy.frontend.ports.proxy.targetPort | int | `6033` | ProxySQL [SQL port](https://proxysql.com/Documentation/global-variables/mysql-variables/#mysql-interfaces) configured in the container |
| services.proxy.frontend.sessionAffinity.type | string | `"None"` | `None` or `ClientIP` if connections from a single client should be [routed to the same endpoint](https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity) every time. |
| services.proxy.frontend.type | string | `"ClusterIP"` | `ClusterIP` to configure a Kubernetes internal service or `LoadBalancer` to publish the service outside of the [Kubernetes cluster network](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| startupProbe.failureThreshold.application | int | 4 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the startup probe for the MariaDB Galera pods is marked as failed |
| startupProbe.failureThreshold.proxy | int | 4 | How many [retries](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) are allowed before the startup probe for the ProxySQL cluster pods is marked as failed |
| startupProbe.initialDelaySeconds.application | int | 60 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the startup probe for MariaDB Galera pods |
| startupProbe.initialDelaySeconds.proxy | int | 60 | Define the [initial delay](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the startup probe for ProxySQL cluster pods |
| startupProbe.periodSeconds.application | int | 30 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the startup probe for MariaDB Galera pods |
| startupProbe.periodSeconds.proxy | int | 30 | Define the [check interval](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) of the startup probe for ProxySQL cluster pods |
| startupProbe.timeoutSeconds.application | int | 20 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the startup probe for the MariaDB Galera pods |
| startupProbe.timeoutSeconds.proxy | int | 20 | How long should Kubernetes [wait](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for the current check of the startup probe for the ProxySQL cluster pods |
| terminationGracePeriodSeconds | int | 86400 | how many seconds should [Kubernetes wait](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-handler-execution) before forcefully stopping a MariaDB Galera and ProxySQL cluster pod. During the MariaDB [full database restore](#full-database-restore) process that value will be reduced to 15 seconds |
| updateStrategy | string | RollingUpdate | [Update strategy](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies) for the MariaDB Galera and ProxySQL cluster pods. |
| userId.application | string | 101 | run the MariaDB containers with that [user id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| userId.monitoring | string | 3000 | run the MariaDB monitoring containers with that [user id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| userId.proxy | string | 3100 | run the ProxySQL containers with that [user id](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container) |
| volumeClaimTemplates.mariadb.accessModes | list | `["ReadWriteOnce"]` | [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for the MariaDB data volume |
| volumeClaimTemplates.mariadb.capacity | string | `"10Gi"` | capacity for the MariaDB data volume |
| volumeClaimTemplates.mariadb.storageClassName | bool | `false` | custom storageclass (currently `cinder` and `nfs` are supported) for the MariaDB data volume |
| volumeClaimTemplates.marialog.accessModes | list | `["ReadWriteOnce"]` | [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for the MariaDB log volume |
| volumeClaimTemplates.marialog.capacity | string | `"30Gi"` | capacity for the MariaDB log volume |
| volumeClaimTemplates.marialog.storageClassName | bool | `false` | custom storageclass (currently `cinder` and `nfs` are supported) for the MariaDB log volume |
| volumeClaimTemplates.proxysql.accessModes | list | `["ReadWriteOnce"]` | [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for the ProxySQL data volume |
| volumeClaimTemplates.proxysql.capacity | string | `"128Mi"` | capacity for the ProxySQL data volume |
| volumeClaimTemplates.proxysql.storageClassName | bool | `false` | custom storageclass (currently `cinder` and `nfs` are supported) for the ProxySQL data volume |
| volumeMounts.application.cert-wildcard.mountPath | string | `"/opt/mariadb/etc/certs"` | if a `cert-wildcard` Kubernetes secret has been defined it will be mounted into that directory |
| volumeMounts.application.cert-wildcard.readOnly | bool | `true` | `true` to [mount the secret](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod) in read only mode |
| volumeMounts.application.cert-wildcard.type | string | `"secret"` | volume type [(secret)](https://kubernetes.io/docs/concepts/storage/volumes/#secret) |
| volumeMounts.application.data.claimName | string | `"mariadb"` | name for the [persistent volume claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) requested for the MariaDB [data directory](https://mariadb.com/kb/en/server-system-variables/#datadir) |
| volumeMounts.application.data.mountPath | string | `"/opt/mariadb/data"` | mount path of the persistent volume in the container used for the MariaDB data directory |
| volumeMounts.application.data.type | string | `"persistentVolume"` | volume type [(persistent)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) |
| volumeMounts.application.log.claimName | string | `"marialog"` |  |
| volumeMounts.application.log.mountPath | string | `"/opt/mariadb/log"` | mount path of the persistent volume in the container used for the MariaDB log directory |
| volumeMounts.application.log.type | string | `"persistentVolume"` | volume type [(persistent)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) |
| volumeMounts.proxy.data.claimName | string | `"proxysql"` | name for the [persistent volume claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) requested for the ProxySQL [data directory](https://proxysql.com/documentation/configuration-file/#general-variables) |
| volumeMounts.proxy.data.mountPath | string | `"/opt/proxysql/data"` | mount path of the persistent volume in the container used for the for the ProxySQL data directory |
| volumeMounts.proxy.data.type | string | `"persistentVolume"` | volume type [(persistent)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) |

### network config

If you want/have to specify a certain network (currently only supported for the Openstack infrastructure provider) for load balancer network services like the [MariaDB frontend](businessbean/helm-charts/blob/master/common/mariadb-galera/helm/values.yaml#L142) these properties have to be provided during the installation of a release.

* `--set OpenstackFloatingNetworkId=$(openstack network show <external network name> -f value -c id)`
* `--set OpenstackFloatingSubnetId=$(openstack subnet list --name <external subnet name> --network <external network name> -f value -c ID)`
* `--set OpenstackSubnetId=$(openstack subnet list --name <private subnet name> --network <private network name> -f value -c ID)`

The [Openstack cloud provider documentation](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/openstack-cloud-controller-manager/expose-applications-using-loadbalancer-type-service.md) has the details about these and more network settings.

### database backup
* The scheduled [backup](#backup) can be enabled and configured in the `mariadb.galera.backup` section
* a Kubernetes cronjob will be configured
* [mariadb-dump](https://mariadb.com/kb/en/mariadb-dumpmysqldump/) will be used to create a logical backup of all databases
* mariadb-binlog will be used to include the existing binary logs in the backup. That allows to do a point in time recovery in addition to the full restore of the database
* restic will be used to encrypt, compress and deduplicate the backup data. Currently the Openstack Swift backend is supported

### full database restore
* prepare the database nodes with the `mariadb.wipeDataAndLog` option
  * the mariadb pods will be restarted
  * the content of the `data` and the `log` folders will be wiped
  * the first pod will start MariaDB with Galera
  * the other pods will only start a sleep process
  * the backup cronjob and the ProxySQL pods will disabled
    ```shell
    helm upgrade --install --namespace database mariadb-galera helm --set mariadb.wipeDataAndLog=true
    ```
  * check the logs of the first MariaDB pod for the wipe and Galera startup messages
    ```json
    {"log.origin.function":"wipedata","log.level":"info","message":"starting wipe of data and log folder content"}
    {"log.origin.function":"wipedata","log.level":"info","message":"wipe of data and log folder content done"}
    {"..."}
    {"log.origin.function":"bootstrapgalera","log.level":"info","message":"init Galera cluster"}
    {"..."}
    ```
    ```text
    [Note] mariadbd: ready for connections.
    Version: '10.5.18-MariaDB-1:10.5.18+maria~ubu2004-log'  socket: '/opt/mariadb/run/mariadbd.sock'  port: 3306  mariadb.org binary distribution
    [Note] WSREP: Starting applier thread 21
    ```
  * check the logs of the other MariaDB pod for the wipe and sleep startup messages
    ```json
    {"log.origin.function":"wipedata","log.level":"info","message":"starting wipe of data and log folder content"}
    {"log.origin.function":"wipedata","log.level":"info","message":"wipe of data and log folder content done"}
    {"..."}
    {"log.origin.function":"initgalera","log.level":"info","message":"start sleep mode because wipedata flag has been set"}
    ```
* start the restore and recovery process using the `mariadb.galera.restore.beforeTimestamp` option
  * a new job pod will be started
  * restic will query the nearest snapshot id related to the provided timestamp
  * the MariaDB dump included in the snapshot will be restored
  * the mysql client will import the dump into the first MariaDB node
    ```sh
    helm upgrade --install --namespace database mariadb-galera helm --set mariadb.galera.restore.enabled=true --set mariadb.galera.restore.beforeTimestamp="2022-12-13 12:00:00"
    ```
  * check the recovery logs of the `mariadb-g-restore-*` pod
    ```json
    {"log.origin.function":"recoverresticdbbackup","log.level":"info","message":"fetch restic snapshotid for 2022-12-13 12:00:00 timestamp"}
    {"log.origin.function":"recoverresticdbbackup","log.level":"info","message":"restic database recovery using snapshot dfca4aaa to mariadb-g-0.database.svc.cluster.local started"}
    {"log.origin.function":"recoverresticdbbackup","log.level":"info","message":"restic database recovery done"}
    ```
* run `helm upgrade` again to remove the `mariadb.wipeDataAndLog` and `mariadb.galera.restore.enabled` options
  * ProxySQL, the config job and the Backup cronjob will be enabled again (if they have been enabled before)
  * the MariaDB pods will be restarted and Galera will replicate the restored data
    ```sh
    helm upgrade --install --namespace database mariadb-galera helm
    ```

### asynchronous replication config

The Helm chart supports circular asynchronous replication between two Galera clusters. Other topologies are technical possible, but not tested.

* configure the `gtidDomainId` and `gtidDomainIdCount` in the custom configuration files `helm/custom/eu-de-2.yaml` and `helm/custom/eu-nl-1.yaml` of your Galera instances and make sure `asyncReplication.enabled=false` is defined
* eu-de-2
```yaml
mariadb:
  galera:
    gtidDomainId: 1
    gtidDomainIdCount: 2
  asyncReplication:
    enabled: false
```
* eu-nl-1
```yaml
mariadb:
  galera:
    gtidDomainId: 2
    gtidDomainIdCount: 2
  asyncReplication:
    enabled: false
```
* if the two Galera cluster are not running in the same Kubernetes cluster or you are not running a service mesh between the Kubernetes clusters you have to expose the MySQL service via a load balancer
* add the service definition to the custom configuration files of both instances
```yaml
services:
  application:
    frontend:
      type: LoadBalancer
```
* install both Galera cluster instances using their custom configuration files
```bash
helm upgrade --install --create-namespace --namespace database mariadb-galera helm --values helm/custom/eu-de-2.yaml
helm upgrade --install --create-namespace --namespace database mariadb-galera helm --values helm/custom/eu-nl-1.yaml
```
* query the load balancer ip of the eu-de-2 instance and add it to the custom configuration of eu-nl-1
* eu-de-2
```bash
kubectl get svc/mariadb-g-frontend-direct --namespace database -o jsonpath={.status.loadBalancer.ingress[0].ip}
```
* eu-nl-1
```yaml
mariadb:
  asyncReplication:
    primaryHost: 10.237.116.19
```
* create a `mariadb-dump` backup from eu-de-2 and restore it in eu-nl-1
* eu-nl-1
```bash
kubectl exec -i pod/mariadb-g-0 -c db -- bash -c 'mariadb-dump --protocol=tcp --host=10.237.116.19 --port=3306 --user=root --password=pass --all-databases --add-drop-database --flush-logs --hex-blob --events --routines --comments --triggers --skip-log-queries --gtid --master-data=1 --single-transaction | mysql --protocol=socket --user=${MARIADB_ROOT_USER}'
```
* enable the replication in the custom configuration of eu-nl-1 and rollout that change
```yaml
mariadb:
  asyncReplication:
    enabled: true
```
* eu-nl-1
```bash
helm upgrade --install --create-namespace --namespace database mariadb-galera helm --values helm/custom/eu-nl-1.yaml
```
* you can check the configuration pod logs for the status of the replication config
```json
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"stopasyncreplication","log.level":"info","message":"stop async replication"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"stopasyncreplication","log.level":"info","message":"replica stop successful"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"setupasyncreplication","log.level":"info","message":"setup async replication from '10.237.116.19'"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"setupasyncreplication","log.level":"debug","message":"master config successfully updated"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"startasyncreplication","log.level":"info","message":"start async replication"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"startasyncreplication","log.level":"info","message":"replica start successful"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"checkasyncreplication","log.level":"info","message":"check async replication status"}
{"@timestamp":"2022-11-19T20:15:18+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"checkasyncreplication","log.level":"error","message":"replica still trying to connect to the primary(20 retries left)"}
{"@timestamp":"2022-11-19T20:15:24+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"checkasyncreplication","log.level":"info","message":"async replication active"}
{"@timestamp":"2022-11-19T20:15:24+UTC","ecs.version":"1.6.0","log.logger":"/opt/mariadb/bin/entrypoint-job-config.sh","log.origin.function":"null","log.level":"info","message":"configuration job finished"}
```
* query the load balancer ip of the eu-de-2 instance and add it to the custom configuration of eu-nl-1
* eu-nl-1
```bash
kubectl get svc/mariadb-g-frontend-direct --namespace database -o jsonpath={.status.loadBalancer.ingress[0].ip}
```
* eu-de-2
```yaml
mariadb:
  asyncReplication:
    primaryHost: 10.47.40.223
```
* enable the replication in the custom configuration of eu-de-2 and rollout that change with the additional `mariadb.asyncReplication.resetConfig=true` (gtid_slave_pos on eu-de-2 will be updated with the gtid_binlog_pos from eu-nl-1)
* the next `helm upgrade` without `resetConfig=true` will make sure that future configuration jobs will not reset the id again to avoid data loss or duplicates
```yaml
mariadb:
  asyncReplication:
    enabled: true
```
* eu-de-2
```bash
helm upgrade --install --create-namespace --namespace database mariadb-galera helm --values helm/custom/eu-de-2.yaml --set mariadb.asyncReplication.resetConfig=true
```
* also here you can check the configuration pod logs for the status of the replication config

### MariaDB Galera flow charts
During their lifecycle several decisions have to be made for the database nodes (running in containers) before actually starting the MariaDB process. Some decicions even have to be made during the runtime of the process.
#### node startup
##### container start
```mermaid
flowchart TB;
  id1[start container]-->id2(run entrypoint.sh)-->id3(include common-functions.sh)-->id4(common-functions-extended.sh exist?);
  id4--Yes-->id5(include common-functions-extended.sh)-->id6;
  id4--No-->id6;
  subgraph idsub1 [wipedata]
    id6(/opt/mariadb/etc/wipedata.flag exist?);
    id6--Yes-->id7(wipe data & log dir content ok?);
  end
  id6--No-->id8;
  id7--Yes-->id8;
  subgraph idsub2 [checkenv]
    id8(required env vars set?);
  end
  id8--Yes-->id9;
  subgraph idsub3 [templateconfig]
    id9(template MariaDB configs ok?);
  end
  id9--Yes-->id10([init database])
  id7--No-->id666[exit 1];
  id8--No-->id666[exit 1];
  id9--No-->id666[exit 1];

click id2 href "businessbean/helm-charts/blob/master/common/mariadb-galera/mariadb-galera/bin/entrypoint.sh" "Open this in a new tab" _blank;
click id3 href "businessbean/helm-charts/blob/master/common/mariadb-galera/docker/mariadb-galera/bin/common-functions.sh" "Open this in a new tab" _blank;
click id4 href "businessbean/helm-charts/blob/master/common/mariadb-galera/helm/scripts/common-functions-extended.sh" "Open this in a new tab" _blank;
```

##### init database
```mermaid
flowchart TB;
  id1([container start])-->id2;
  subgraph idsub1 [initdb]
    id2(database already exist?)--No-->id3(mariadb-install-db ok?);
    subgraph idsub2 [startmaintenancedb]
      id3--Yes-->id4(start mariadbd in background ok?);
    end
    subgraph idsub3 [setuptimezoneinfo]
      id4--Yes-->id5(setup timezone infos ok?)
    end
    subgraph idsub4 [setuprole]
      id5--Yes-->id6(setup role fullaccess ok?)
      id6--Yes-->id7(setup role mysql_exporter ok?)
    end
    subgraph idsub5 [setupuser]
      id7--Yes-->id8(setup MARIADB_ROOT_USER ok?)
      id8--Yes-->id9(setup MARIADB_MONITORING_USER ok?)
    end
    subgraph idsub6 [listdbandusers]
      id9--Yes-->id10(list users from database ok?)
    end
    subgraph idsub7 [stopdb]
      id10--Yes-->id11(shutdown database ok?)
    end
  end
  subgraph idsub8 [checkupgradedb]
    id2--Yes-->id12(mysql_upgrade_info exist?);
    id11--Yes-->id12;
    id12--Yes-->id16(mariadb binary newer than db?);
    subgraph idsub9 [startmaintenancedb]
      id12--No-->id13(start mariadbd in background ok?);
      id16--Yes-->id13;
      subgraph idsub10 [upgradedb]
        id13--Yes-->id14(mysql_upgrade ok?);
      end
      subgraph idsub11 [stopdb]
        id14--Yes-->id15(shutdown database ok?)
      end
    end
  end
  subgraph idsub15 [startdb]
    id15--Yes-->id20(entrypoint-galera.sh exist?);
    id16--No-->id20;
    id20--No-->id99(exec mariadbd ok?)--Yes-->id98(MariaDB running);
  end
  id20--Yes-->id21([init Galera]);

  subgraph failure
    id3 & id4 & id5 & id6 & id7 & id8 & id9--No-->id666[exit 1];
    id10 & id11 & id13 & id14 & id15 & id99--No-->id666;
  end

click id20 href "businessbean/helm-charts/blob/master/common/mariadb-galera/helm/scripts/mariadb-galera/entrypoint-galera.sh" "Open this in a new tab" _blank;
click id6 href "businessbean/helm-charts/blob/master/common/mariadb-galera/docker/mariadb-galera/config/fullaccess.role.yaml" "Open this in a new tab" _blank;
click id7 href "businessbean/helm-charts/blob/master/common/mariadb-galera/docker/mariadb-galera/config/mysql_exporter.role.yaml" "Open this in a new tab" _blank;
```

##### init Galera

```mermaid
flowchart TB;
  id1([init database])-->id2;

  subgraph idsub1 [initgalera]
    id2(grastate.dat exist?);
    id2--No-->id3(hostname eq pod 0 name?)--Yes-->id4;
    id3--No-->id6(join cluster);
    subgraph idsub2 [bootstrapgalera]
      id4(bootstrap cluster)-->id5(exec mariadbd --wsrep-new-cluster ok?);
    end
    subgraph idsub3 [startgalera]
      id6-->id7(exec mariadbd ok?);
    end
  end
  id2--Yes-->id9([recover Galera]);
  subgraph idsub4 [Done]
    id5 & id7--Yes-->id98(MariaDB running);
  end
  subgraph failure
    id5 & id7--No-->id666[exit 1];
  end
```
##### recover Galera

```mermaid
flowchart TB;
  id1([init Galera])-->id2;
  subgraph idsub1 [initgalera]
    id2(safe_to_bootstrap=1 and sequence number not -1 ?)--Yes-->id3;
    subgraph idsub2 [setconfigmap]
      id3(update sequence number in configmap ok?);
    end
    subgraph idsub3 [selectbootstrapnode]
      id3--Yes-->id4(seqno file count -ge pod replicas?);
      id4--Yes-->id5(fetch seqno timestamps ok?);
      id5--Yes-->id6(useTimeDifferenceForSeqnoCheck=true?);
      id6--Yes-->id7(timestamps are recent?);
      id6--No-->id8;
      id7--Yes-->id8(nodename with highest sequence number found?);
      id8--Yes-->id9(nodename selected?);
    end
    id2--No-->id10(mariadbd --wsrep-recover to find uuid and seqno ok?);
    id10--Yes-->id11(update seqno and historic UUID in grastate.dat ok?)--Yes-->id3;
  end
  id9--No-->id13([bootstrap Galera]);
  subgraph failure
    id4 & id5 & id7 & id8 & id9 & id10 & id11--No-->id666[exit 1];
  end
```

##### bootstrap Galera

```mermaid
flowchart TB;
  id1([recover Galera])-->id2;
  subgraph idsub1 [recovergalera]
    id2(nodename eq hostname of container?);
    id2--Yes-->id3(mariadbd --wsrep-recover was required?)--Yes-->id4(set 'safe_to_bootstrap: 1' in grastate.dat ok?);
    id2--No-->id5(join cluster);
    id3--No-->id7;
    id4--Yes-->id7;
    subgraph idsub2 [bootstrapgalera]
      id7(bootstrap cluster)-->id8(exec mariadbd --wsrep-new-cluster ok?);
    end
    subgraph idsub3 [startgalera]
      id5-->id6(exec mariadbd ok?);
    end
  end
  subgraph idsub6 [Done]
    id6 & id8--Yes-->id98(MariaDB running);
  end
  subgraph failure
    id4 & id6 & id8--No-->id666[exit 1];
  end
```

## additional documentation
### Database
* [MariaDB server system variables](https://mariadb.com/kb/en/server-system-variables/)
* [mysql_install_db parameters](https://mariadb.com/kb/en/mysql_install_db/)
* [MariaDB install packages](https://mariadb.org/download/?t=repo-config&d=20.04+%22focal%22&v=10.5&r_m=hs-esslingen)
* [MariaDB automation](https://mariadb.com/kb/en/automated-mariadb-deployment-and-administration/)
* [MariaDB Environment Variables](https://mariadb.com/kb/en/mariadb-environment-variables/)
* [Overview of MariaDB Logs](https://mariadb.com/kb/en/overview-of-mariadb-logs/)

### Galera cluster
* [Galera cluster description](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/)
* [Galera getting started](https://mariadb.com/kb/en/getting-started-with-mariadb-galera-cluster/)
* [Configuring MariaDB Galera Cluster](https://mariadb.com/kb/en/configuring-mariadb-galera-cluster/)
* [Using MariaDB GTIDs with MariaDB Galera Cluster](https://mariadb.com/kb/en/using-mariadb-gtids-with-mariadb-galera-cluster/)
* [Galera monitoring](https://galeracluster.com/library/documentation/monitoring-cluster.html)
* [Galera Crash recovery](https://galeracluster.com/library/documentation/crash-recovery.html)
* [Primary recovery after clean shutdown of the cluster](https://galeracluster.com/library/documentation/pc-recovery.html)
* [calculate the Galera Cache Size for IST(Incremental State Transfer)](https://galeracluster.com/library/kb/customizing-gcache-size.html)
* [custom pc.weight for predictable quorum decisions](https://galeracluster.com/library/documentation/weighted-quorum.html#wq-three-nodes)
* [check Galera replication health](https://galeracluster.com/library/documentation/monitoring-cluster.html#check-replication-health)
  * `wsrep_local_recv_que_avg` should be 0 (indicates if the local cluster node is not fast enough to apply the changes)
  * `wsrep_flow_control_paused` should be 0 (0.25 means 25% of the time replication was paused)
  * `wsrep_cert_deps_distance` difference between lowest and highest sequence number in the cluster
* [Setting Parallel Slave Threads for replication](https://galeracluster.com/library/kb/parallel-applier-threads.html)

### Primary/Replica replication
* [Global Transaction ID](https://mariadb.com/kb/en/gtid/)
* [Configuring MariaDB Replication between Two MariaDB Galera Clusters](https://mariadb.com/kb/en/configuring-mariadb-replication-between-two-mariadb-galera-clusters/)
* [Configuring MariaDB Replication between MariaDB Galera Cluster and MariaDB Server](https://mariadb.com/kb/en/using-mariadb-replication-with-mariadb-galera-cluster-configuring-mariadb-r/)
* [Replication Overview](https://mariadb.com/kb/en/replication-overview/)
* [Replication Filters](https://mariadb.com/kb/en/replication-filters/)
* [Reset Replica config](https://mariadb.com/kb/en/reset-replica/)
* [CHANGE MASTER TO](https://mariadb.com/kb/en/change-master-to/) command options
* [Multi-Source Replication with MariaDB Galera Cluster](https://severalnines.com/blog/multi-source-replication-mariadb-galera-cluster)
* [Parallel Replication](https://mariadb.com/kb/en/parallel-replication/)
* [MariaDB Galera Cluster and M/S replication](https://archive.fosdem.org/2022/schedule/event/mariadb_galera/)
* [MariaDB Master/Master GTID based replication](https://www.fromdual.com/mariadb-master-master-gtid-based-replication-with-keepalived-vip)

### Monitoring
* [Unit Testing for Prometheus exporters](https://www.prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)

### Backup
* [Galera Backup options](https://galeracluster.com/library/training/tutorials/galera-backup.html)
  * [Backing Up Cluster Data](https://galeracluster.com/library/documentation/backup-cluster.html)
  * [Scriptable State Snapshot Transfers](https://galeracluster.com/library/documentation/scriptable-sst.html)
  * [mariabackup SST Method](https://mariadb.com/kb/en/mariabackup-sst-method/)
  * [manual Cluster backup with mariabackup](https://mariadb.com/kb/en/manual-sst-of-galera-cluster-node-with-mariabackup/)
  * [mariabackup commandline options](https://mariadb.com/kb/en/mariabackup-options/)
  * [mariadb-dump manual](https://mariadb.com/kb/en/mariadb-dumpmysqldump/)
  * [Mariabackup + Restic: a simple and efficient online backup solution for your DBs](https://archive.fosdem.org/2022/schedule/event/mariadb_backup_restic/)
  * [MariaDB Point-in-Time-Recovery](https://archive.fosdem.org/2022/schedule/event/mariadb_pit_recovery/)

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
