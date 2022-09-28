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
```mermaid
flowchart TD;
    id1[start container]-->id2(run entrypoint.sh)-->id3(include common-functions.sh)-->id128(common-functions-extended.sh exist?);
    id128--Yes-->id129(include common-functions-extended.sh)-->id4;
    id128--No-->id4;
    subgraph idsub1 [checkenv]
      id4(required env vars set?);
    end
    subgraph idsub2 [initdb]
      id4--Yes-->id5(database already exist?)--No-->id6(mariadb-install-db ok?);
      subgraph idsub3 [startmaintenancedb]
        id6--Yes-->id7(start mariadbd in background ok?);
      end
      subgraph idsub4 [setuptimezoneinfo]
        id7--Yes-->id8(setup timezone infos ok?)
      end
      subgraph idsub5 [setuprole]
        id8--Yes-->id9(setup role fullaccess ok?)
        id9--Yes-->id10(setup role mysql_exporter ok?)
      end
      subgraph idsub6 [setupuser]
        id10--Yes-->id11(setup MARIADB_ROOT_USER ok?)
        id11--Yes-->id12(setup MARIADB_MONITORING_USER ok?)
      end
      subgraph idsub7 [listdbandusers]
        id12--Yes-->id13(list users from database ok?)
      end
      subgraph idsub8 [stopdb]
        id13--Yes-->id14(shutdown database ok?)
      end
    end
    subgraph idsub9 [checkupgradedb]
      id5--Yes-->id15(mysql_upgrade_info exist?);
      id14--Yes-->id15;
      subgraph idsub10 [startmaintenancedb]
        id15--No-->id16(start mariadbd in background ok?);
        subgraph idsub11 [upgradedb]
          id16--Yes-->id17(mysql_upgrade ok?);
        end
        subgraph idsub12 [stopdb]
          id17--Yes-->id18(shutdown database ok?)
        end
      end
      id15--Yes-->id19(mariadb binary newer than db?);
      subgraph idsub13 [startmaintenancedb]
        id19--Yes-->id20(start mariadbd in background ok?);
        subgraph idsub14 [upgradedb]
          id20--Yes-->id21(mysql_upgrade ok?);
        end
        subgraph idsub15 [stopdb]
          id21--Yes-->id22(shutdown database ok?)
        end
      end
    end
    subgraph idsub16 [startdb]
      id18--Yes-->id23(entrypoint-galera.sh exist?);
      id22--Yes-->id23;
      subgraph idsub17 [templateconfig]
        id23--Yes-->id24(template MariaDB configs ok?);
      end
      subgraph idsub18 [initgalera]
        id24--Yes-->id25(grastate.dat exist?);
        subgraph idsub19 [recovergalera]
          id25--Yes-->id26(PC_RECOVERY=true and gvwstate.dat exist?);
          subgraph idsub20 [startgalera]
            id26--Yes-->id27(exec mariadbd ok?);
          end
          id26--No-->id28(safe_to_bootstrap=1 and sequence number not -1 ?);
          id28--Yes-->id42(update sequence number in configmap);
          subgraph idsub21 [setconfigmap]
            id42-->id29(update configmap ok?);
          end
          subgraph idsub22 [selectbootstrapnode]
            id29--Yes-->id30(seqno file count -ge pod replicas?);
            id30--Yes-->id31(fetch seqno timestamps ok?);
            id31--Yes-->id32(useTimeDifferenceForSeqnoCheck=true and timestamps are recent?);
            id32--Yes-->id33(nodename with highest sequence number found?);
            id33--Yes-->id34(nodename selected);
          end
          id34-->id35(nodename eq hostname of container?);
          id35--Yes-->id36(set safe_to_bootstrap: 1 in grastate.dat ok?);
          id35--No-->id39(join cluster);
          subgraph idsub23 [bootstrapgalera]
            id36--Yes-->id37(bootstrap cluster)-->id38(exec mariadbd --wsrep-new-cluster ok?);
          end
          subgraph idsub24 [startgalera]
            id39-->id40(exec mariadbd ok?);
          end
          id28--No-->id41(mariadbd --wsrep-recover to find uuid and seqno ok?);
          id41--Yes-->id43(update seqno and uuid in grastate.dat ok?);
          subgraph idsub25 [setconfigmap]
            id43-->id44(update configmap ok?);
          end
          subgraph idsub26 [selectbootstrapnode]
            id44--Yes-->id45(seqno file count -ge pod replicas?);
            id45--Yes-->id46(fetch seqno timestamps ok?);
            id46--Yes-->id47(useTimeDifferenceForSeqnoCheck=true and timestamps are recent?);
            id47--Yes-->id48(nodename with highest sequence number found?);
            id48--Yes-->id49(nodename selected);
          end
          id49-->id50(nodename eq hostname of container?);
          id50--Yes-->id51(set safe_to_bootstrap: 1 in grastate.dat ok?);
          id50--No-->id52(join cluster);
          subgraph idsub27 [bootstrapgalera]
            id51-->id53(bootstrap cluster)-->id54(exec mariadbd --wsrep-new-cluster ok?);
          end
          subgraph idsub28 [startgalera]
            id52--No-->id55(exec mariadbd ok?);
          end
        end
      end
    end
    subgraph idsub29 [Done]
      id23--No-->id99(exec mariadbd ok?)--Yes-->id98(MariaDB running);
      id27--Yes-->id98(MariaDB running);
      id38--Yes-->id98(MariaDB running);
      id40--Yes-->id98(MariaDB running);
      id54--Yes-->id98(MariaDB running);
      id55--Yes-->id98(MariaDB running);
    end
    subgraph exit
      id4--No-->id666[exit 1];
      id6--No-->id666;
      id7--No-->id666;
      id8--No-->id666;
      id9--No-->id666;
      id10--No-->id666;
      id11--No-->id666;
      id12--No-->id666;
      id13--No-->id666;
      id14--No-->id666;
      id16--No-->id666;
      id17--No-->id666;
      id18--No-->id666;
      id20--No-->id666;
      id21--No-->id666;
      id22--No-->id666;
      id24--No-->id666;
      id27--No-->id666;
      id29--No-->id666;
      id30--No-->id666;
      id31--No-->id666;
      id32--No-->id666;
      id33--No-->id666;
      id36--No-->id666;
      id38--No-->id666;
      id40--No-->id666;
      id41--No-->id666;
      id43--No-->id666;
      id44--No-->id666;
      id45--No-->id666;
      id46--No-->id666;
      id47--No-->id666;
      id48--No-->id666;
      id54--No-->id666;
      id55--No-->id666;
      id99--No-->id666;
    end

click id2 href "docker/mariadb-galera/bin/entrypoint.sh" "Open this in a new tab" _blank;
click id3 href "docker/mariadb-galera/bin/common-functions.sh" "Open this in a new tab" _blank;
click id9 href "docker/mariadb-galera/config/fullaccess.role.yaml" "Open this in a new tab" _blank;
click id10 href "docker/mariadb-galera/config/mysql_exporter.role.yaml" "Open this in a new tab" _blank;
click id23 href "helm/scripts/mariadb-galera/entrypoint-galera.sh" "Open this in a new tab" _blank;
click id128 href "helm/scripts/common-functions-extended.sh" "Open this in a new tab" _blank;
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
