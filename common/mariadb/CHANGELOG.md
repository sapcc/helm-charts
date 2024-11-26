# Changelog

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
