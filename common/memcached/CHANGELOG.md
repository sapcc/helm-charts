# Changelog

## v0.6.14 - 2026/01/15

* memcached bumped to `1.6.40-alpine3.23`
* chart version bumped

## v0.6.13 - 2025/12/16

* memcached bumped to `1.6.39-alpine3.23`
* memcached-exporter [version](https://github.com/prometheus/memcached_exporter/releases/tag/v0.15.4) bumped to `v0.15.4`
* chart version bumped

## v0.6.12 - 2025/08/04

* memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1639) bumped to `1.6.39-alpine3.22`
  * TLS and proxy fixes
* chart version bumped

## v0.6.11 - 2025/07/23
* Use `1.6.38-alpine3.22` image
* SASL fixes:
  * change data key name in `memcached-config` ConfigMap to `data`
  * set pod hostname when SASL is enabled
  * add newline to `sasl_pwdb` secret and pod hostname to the username

## v0.6.10 - 2025/04/14
* add option to set vpa main container

## v0.6.9 - 2025/03/25

* Set type: LoadBalancer in case of external IP
* needed for global/calico rollout
* chart version bumped

## v0.6.8 - 2025/03/24

* Set Service 'externalTrafficPolicy: Local' when using external IP.
* needed for calico rollout
* chart version bumped

## v0.6.7 - 2025/03/21

memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1638) bumped to `1.6.38-alpine3.21`
  * mem leak fix and other small fixes
* chart version bumped

## v0.6.6 - 2025/03/04

* memcached-exporter [version](https://github.com/prometheus/memcached_exporter/releases/tag/v0.15.1) bumped to `v0.15.1`
* chart version bumped

## v0.6.5 - 2025/02/24

* memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1637) bumped to `1.6.37-alpine3.21`
  * `proto: -X disables stats detail as well` to make information leakage harder
* chart version bumped

## v0.6.4 - 2025/02/07

* memcached [version](https://github.com/memcached/memcached/wiki/ReleaseNotes1636) bumped to `1.6.36-alpine3.21`
  * `Critical bugfix for the proxy when using an "internal" backend with extstore enabled. Does not affect the system otherwise.`
* chart version bumped

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
