# mariadb-galera
Docker image and Helm chart to deploy a [MariaDB](https://mariadb.com/kb/en/getting-installing-and-upgrading-mariadb/) HA cluster based on [Galera](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/)

## additional documentation
* [MariaDB server system variables](https://mariadb.com/kb/en/server-system-variables/)
* [mysql_install_db parameters](https://mariadb.com/kb/en/mysql_install_db/)
* [MariaDB install packages](https://mariadb.org/download/?t=repo-config&d=20.04+%22focal%22&v=10.5&r_m=hs-esslingen)
* [MariaDB automation](https://mariadb.com/kb/en/automated-mariadb-deployment-and-administration/)
* [Galera cluster description](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/)
* [Galera getting started](https://mariadb.com/kb/en/getting-started-with-mariadb-galera-cluster/)
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
* [Unit Testing for Prometheus exporters](https://www.prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)

## MariaDB Galera flow charts
During their lifecycle several decisions have to be made for the database nodes (running in containers) before actually starting the MariaDB process. Some decicions even have to be made during the runtime of the process.
### node startup
#### container start
```mermaid
flowchart TB;
  id1[start container]-->id2(run entrypoint.sh)-->id3(include common-functions.sh)-->id4(common-functions-extended.sh exist?);
  id4--Yes-->id5(include common-functions-extended.sh)-->id6;
  id4--No-->id6;
  subgraph idsub1 [checkenv]
    id6(required env vars set?);
  end
  id6--Yes-->id7([init database])
  id6--No-->id666[exit 1];

click id2 href "businessbean/helm-charts/blob/master/common/mariadb-galera/mariadb-galera/bin/entrypoint.sh" "Open this in a new tab" _blank;
click id3 href "businessbean/helm-charts/blob/master/common/mariadb-galera/docker/mariadb-galera/bin/common-functions.sh" "Open this in a new tab" _blank;
click id4 href "businessbean/helm-charts/blob/master/common/mariadb-galera/helm/scripts/common-functions-extended.sh" "Open this in a new tab" _blank;
```

#### init database
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

#### init Galera

```mermaid
flowchart TB;
  id1([init database])-->id2;
  subgraph idsub1 [templateconfig]
    id2(template MariaDB configs ok?);
  end
  subgraph idsub2 [initgalera]
    id2--Yes-->id3(grastate.dat exist?);
    subgraph idsub3 [recovergalera]
      id3--Yes-->id4(PC_RECOVERY=true and gvwstate.dat exist?);
      subgraph idsub4 [startgalera]
        id4--Yes-->id5(exec mariadbd ok?)--Yes-->id98(MariaDB running);
      end
    end
  end
  id3--No-->id6([recover Galera]);
  subgraph failure
    id2 & id5--No-->id666[exit 1];
  end
```
#### recover Galera

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
    id5 & id6 & id8 & id9 & id10 & id11--No-->id666[exit 1];
  end
```

#### bootstrap Galera

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
## Docker image

### build the image

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

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.67 --build-arg SOFT_NAME=mariadb --build-arg SOFT_VERSION=10.5.17+maria~ubu2004 --build-arg IMG_VERSION=0.1.2 --build-arg GALERA_VERSION=26.4.12-focal --build-arg YQ_VERSION=4.27.5 -t keppel.eu-de-1.cloud.sap/ccloud/mariadb-galera:10.5.17-0.1.2 -f docker/mariadb-galera/Dockerfile ./docker/mariadb-galera/
```

#### debug build

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.67 --build-arg SOFT_NAME=mariadb --build-arg SOFT_VERSION=10.5.17+maria~ubu2004 --build-arg IMG_VERSION=0.1.2 --build-arg GALERA_VERSION=26.4.12-focal --build-arg YQ_VERSION=4.27.5 --build-arg GALERA_DEBUG=true -t keppel.eu-de-1.cloud.sap/ccloud/mariadb-galera-debug:10.5.17-0.1.2 -f docker/mariadb-galera/Dockerfile ./docker/mariadb-galera/
```
#### MySQL Exporter image
| build argument | description |
|:--------------|:-------------|
| USERID | id of the user that should run the binary |

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.67 --build-arg SOFT_NAME=mysqld_exporter --build-arg SOFT_VERSION=0.14.0 --build-arg IMG_VERSION=0.1.1 --build-arg USERID=3000 -t keppel.eu-de-1.cloud.sap/ccloud/mysqld_exporter:0.14.0-0.1.1 -f docker/mysqld_exporter/Dockerfile ./docker/mysqld_exporter/
```
#### ProxySQL image
| build argument | description |
|:--------------|:-------------|
| USERID | id of the user that should run the binary |

```bash
docker build --build-arg BASE_REGISTRY=keppel.eu-nl-1.cloud.sap --build-arg BASE_ACCOUNT=octobus --build-arg BASE_SOFT_NAME=ubuntu --build-arg BASE_SOFT_VERSION=20.04 --build-arg BASE_IMG_VERSION=0.3.67 --build-arg SOFT_NAME=proxysql --build-arg SOFT_VERSION=2.4.3 --build-arg IMG_VERSION=0.1.1 --build-arg USERID=3100 -t keppel.eu-de-1.cloud.sap/ccloud/proxysql:2.4.3-0.1.1 -f docker/proxysql/Dockerfile ./docker/proxysql/
```
## Helm chart

### render the chart templates

* `helm template mariadb-galera helm --namespace database`

### deploy the chart

* `helm upgrade --install --create-namespace --namespace database mariadb-galera helm`

### remove the deployed release

* `helm uninstall --namespace database mariadb-galera`
