# Changelog

## v0.18.0 - 2025/02/24

* enable reloader annotation to restart mariadb pod on root password update
* start database with init.sql to update root password
* chart version bumped

## v0.17.0 - 2025/02/21
* use custom entrypoint script for mariadb deployment
  * remove non-optional and `healthcheck` user creation
* chart version bumped

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
