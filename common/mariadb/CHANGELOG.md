# Changelog

## v0.27.1 - 2025/08/13
* MariaDB version updated to [10.11.14](https://mariadb.com/docs/release-notes/community-server/mariadb-10-11-series/mariadb-10.11.14-release-notes)
  * several critical (InnoDB) fixes
* chart version bumped

## v0.27.0 - 2025/07/31
* Added an option to drop the database user using the values configuration

Example:
```yaml
mariadb:
  users:
    test:
      enabled: false
```
This will result in the `test` user being dropped from the MariaDB.

## v0.26.1 - 2025/07/22
* `maria-back-me-up` updated to `20250722132533`
* chart version bumped

## v0.26.0 - 2025/07/22
* MariaDB `userstat` plugin is enabled
* mysqld-exporter now collects user statistics
* chart version bumped

## v0.25.1 - 2025/07/09
* Set `kubectl.kubernetes.io/default-container` annotation for all chart deployments, cronjobs and jobs
* chart version bumped

## v0.25.0 - 2025/07/02
* MariaDB version updated to [10.11.13](https://mariadb.com/kb/en/mariadb-10-11-13-release-notes/)
  * See https://mariadb.com/kb/en/changes-improvements-in-mariadb-1011/
* mysql-exporter version updated to [v0.17.2](https://github.com/prometheus/mysqld_exporter/releases/tag/v0.17.2)
* chart version bumped

## v0.24.2 - 2025/05/27
* MariaDB version bumped to [10.6.22](https://mariadb.com/kb/en/mariadb-10-6-22-release-notes/)
  * InnoDB race condition has been fixed
  * [CVEs fixed](https://mariadb.com/kb/en/security/#full-list-of-cves-fixed-in-mariadb):
    * [CVE-2025-30722](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2025-30722)
    * [CVE-2025-30693](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2025-30693)
    * [CVE-2023-52970](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-52970)
    * [CVE-2023-52969](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-52969)
* chart version bumped

## v0.24.1 - 2025/05/14
* Set `max_connect_errors` option in my.cnf to maximal possible value `4294967295`.
* Set `skip_name_resolve` option to `ON` and `host_cache_size` to 0.

This will prevent blocking database connections because of the failed monitor checks or other network issues.

See related documentation at https://mariadb.com/kb/en/server-system-variables/#max_connect_errors

## v0.24.0 - 2025/04/16
* MariaDB has been updated to the 10.6.21 version
  * delete removed `innodb_thread_concurrency` variable from my.cnf

See related documentation at https://mariadb.com/kb/en/upgrading-from-mariadb-10-5-to-mariadb-10-6/

The default value of the `old_mode` variable is `UTF8_IS_UTF8MB3` until MariaDB 11.2.

## v0.23.0 - 2025/04/10
* reloader annotation has been added to the backup-v2 deployment, so backup-v2 deployment always uses updated credentials

## v0.22.0 - 2025/04/09
* delete unmanaged localhost users like 'username'@'localhost'

Previously, init.sql script was creating a pair of users: 'username'@'%' and 'username'@'localhost'. The second one stopped being managed since the introduction of granular user configuration in 2022. These @'localhost' users will be removed now.

## v0.21.0 - 2025/04/08
* remove version label from mariadb deployment pod template and related configmaps to avoid unnecessary database restarts on simple chart version update

## v0.20.0 - 2025/04/03
* add `renameCheckConstraints`  job, which allows to rename constraints, created by sqlalchemy with names like `CONSTRAINT_*`, to constraints with a unique name, as MySQL does

Context: by default, alembic migrations creating a boolean column causes sqlalchemy to create a check constraint without a specified name like this:
```sql
CONSTRAINT `CONSTRAINT_1` CHECK (`enabled` in (0,1))
```
MariaDB's default behavior is to name constraints like 'CONSTRAINT_1', 'CONSTRAINT_2', and so on. The constraint name being unique per table.
The default behaviour of MySQL (or Percona Server / Percona XtraDB Cluster) is to name constraints like 'table_chk_1', 'table_chk_2', and so on. The constraint name must be unique per database.
This makes data migration from MariaDB to MySQL impossible without renaming constraints, because mysqldump of MariaDB contains many non-unique constraint names.
To solve this problem and make a database dump compatible with MySQL, these constraints should be renamed (recreated) using unique names.

### Job configuration example
```yaml
job:
  renameCheckConstraints:
    enabled: true
```

## v0.19.1 - 2025/04/02
* `set-root-password` init container now always tries to create `'root'@'localhost'` and `'root'@'%'` user if it doesn't exist
  * this helps to avoid lock-out issue, if this user was previously deleted

## v0.19.0 - 2025/03/25
* Remove the following internal helm template helper functions:
  * `keystone_url`
  * `mariadb.db_host`
  * `mariadb.root_password`
  * `mariadb.resolve_secret`

## v0.18.2 - 2025/03/21
* add missing headers to the mariadb-credential-updater.py
* remove unused `credentialUpdater.enabled` option from values - this sidecar is non-optional

## v0.18.1 - 2025/03/21
* make backup storage to AWS and Swift flexibel via enablement in `backup-v2` configuration

## v0.18.0 - 2025/03/07
* add credential-updater sidecar, that reapplies init.sql on the detected change
* make init.sql not optional
* remove pre-change job, because it's no longer needed with the above sidecar
* add missing owner labels to initdb secret

## v0.17.3 - 2025/03/06
* start database with init.sql to always update root password on start

## v0.17.2 - 2025/03/05
* use `shared-app-images/alpine-kubectl` image for pre-change job instead of outdated `unified-kubernetes-toolbox`, that is supposed to be used in CI

## v0.17.1 - 2025/03/04
* use local unix_socket connection for all status checks and mysqld_upgrade
  * this would allow to change root password without intermittent liveness check failure
  * this would allow to use `'` and `\` in root password in mysqld_upgrade
* use monitor user with limited privileges for metrics sidecar

## v0.17.0 - 2025/02/27
* use custom entrypoint script for mariadb deployment
  * remove non-optional and `healthcheck` user creation

## v0.16.10 - 2025/02/27
* verbose logging option for the analyzetables job added
* chart version bumped

## v0.16.9 - 2025/02/26
* maintenance job configmap condition fixed
* chart version bumped

## v0.16.8 - 2025/02/25
* maintenance job configmap name fixed
* chart version bumped

## v0.16.7 - 2025/02/25
* `pod-readiness` updated to `20250225131500`

## v0.16.6 - 2025/02/24
* mysqld_exporter updated to [0.17.1](https://github.com/prometheus/mysqld_exporter/releases/tag/v0.17.1)
* chart version bumped

## v0.16.5 - 2025/02/21
* add `lost+found` to `ignore_db_dirs` list
* chart version bumped

## v0.16.4 - 2025/02/21
* fix maria-back-me-up alert rules

## v0.16.3 - 2025/02/19
* fix names of the maintenance cronjob resources
  * make cm names unique
* chart version bumped

## v0.16.2 - 2025/02/14
- maintenance job added
  - currently the [analyze table](https://mariadb.com/kb/en/analyze-table/) task is supported
  - the[README.md](README.md#analyzetable) is updated with the new maintenance job details
- chart version bumped

## v0.16.1 - 2025/02/18
* enquote password in /root/.my.cnf
  * this would allow to use `=` and `#` symbols in password
* chart version bumped

## v0.16.0 - 2025/02/17
* remove user and password from readiness and liveness probes
  * `/root/.my.cnf` is used instead
  * this helps avoiding problems with shell escaping and showing passwords in the processlist of the k8s nodes
* chart version bumped

## v0.15.5 - 2025/02/14
* `maria-back-me-up` (backup-v2) oauth secret moved to a separate `Secret`
* chart version bumped

## v0.15.4 - 2025/02/07
* MariaDB version bumped to [10.5.28](https://mariadb.com/kb/en/mariadb-10-5-28-release-notes/)
  * several fixes for INNODB and other components
  * memory leaks have been fixed
  * [CVE-2025-21490](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2025-21490) has been fixed
    * a DOS can be triggered from an unauthorized connection
* chart version bumped

## v0.15.3 - 2025/01/14
- fixed service selector: added `app.kubernetes.io/instance` label to make service target specific service instance
- chart version bumped

## v0.15.2 - 2024/11/29
- `app` selector label returned, because deployment selector is immutable
- chart version bumped

## v0.15.1 - 2024/11/28
* mysqld-exporter version bumped to `0.16.0`
* mysqld-exporter `collect.info_schema.innodb_tablespaces` collector enabled

## v0.15.0 - 2024/10/18
* MariaDB version bumped to `10.5.27`
* version info added to labels
  * to allow gatekeeper rules based on them
* old (non-standard) labels removed
* chart version bumped

### label example
```yaml
labels:
  app.kubernetes.io/name: mariadb
  app.kubernetes.io/instance: keystone-mariadb
  app.kubernetes.io/component: mariadb-deployment-database
  app.kubernetes.io/part-of: keystone
  app.kubernetes.io/version: 10.5.27
  app.kubernetes.io/managed-by: "helm"
  helm.sh/chart: mariadb-0.15.0
```
### removed labels
```yaml
labels:
  app: keystone-mariadb
  name: keystone-mariadb
  component: keystone
  system: openstack
  type: database
  chart: "mariadb-0.15.0"
  release: "keystone"
  heritage: "Helm"
```

### Prometheus label names that must be updated
These labels must be updated if you use them in your Prometheus alerts definitions.
- `app` must be `app_kubernetes_io_instance`
- `component` must be `app_kubernetes_io_name`
