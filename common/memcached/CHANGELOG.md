# Changelog

## v0.6.3 - 2025/01/07

* memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1634) bumped to `1.6.34-alpine3.21`
* memcached-exporter [version](https://github.com/prometheus/memcached_exporter/releases/tag/v0.15.0) bumped to `v0.15.0`
* chart version bumped

## v0.6.2 - 2024/12/16

* memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1633) bumped to `1.6.33-alpine3.21`
* chart version bumped

## v0.6.1 - 2024/11/28
* `app` selector label returned, because deployment selector is immutable
* chart version bumped

## v0.6.0 - 2024/10/15
* version info added to labels
  * to allow gatekeeper rules based on them
* old (non-standard) labels removed
* memcached version bumped to `1.6.31-alpine3.20`
  * added alpine version to the tag to enforce exactly this version
* chart version bumped

### label example
```yaml
labels:
  app.kubernetes.io/name: memcached
  app.kubernetes.io/instance: keystone-memcached
  app.kubernetes.io/component: memcached-deployment-kvstore
  app.kubernetes.io/part-of: keystone
  app.kubernetes.io/version: 1.6.31
  app.kubernetes.io/managed-by: "helm"
  helm.sh/chart: memcached-0.6.0
```
### removed labels
```yaml
labels:
   app: keystone-memcached
   component: memcached
   chart: "memcached-0.5.3"
   release: "keystone"
   heritage: "Helm"
   type: configuration
   application: keystone
```
### Prometheus label names that must be updated
These labels must be updated if you use them in your Prometheus alerts definitions.
- `app` must be `app_kubernetes_io_instance`
- `component` must be `app_kubernetes_io_name`
