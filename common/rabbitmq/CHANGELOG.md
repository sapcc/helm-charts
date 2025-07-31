# Rabbitmq CHANGELOG

This file is used to list changes made in each version of the common chart rabbitmq.

## 0.18.7 - 2025/07/31

- Limit default commonName in certificate to 64 characters as that is the limit.


## 0.18.6 - 2025/07/30

- Update [user-credential-updater](https://github.com/sapcc/rabbitmq-user-credential-updater) sidecar container to `20250730094138` version with bugfixes.
- Chart version bumped

## 0.18.5 - 2025/07/07

- RabbitMQ [4.1.2 Release notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.1.2)
- Chart version bumped

## 0.18.4 - 2025/07/01

- Drop `externalIps` from certificate, as they are unsupported by our certificate provider.
  They still can be added with `certificate.ipAddresses`


## 0.18.3 - 2025/07/01

- Default to ClusterIssuer with the name "digicert-issuer"


## 0.18.2 - 2025/06/30

- Removed the default for CN (common name) from the certificate, as it is too long
- Switched ClusterIssuer group from `cert-manager.io` to `certmanager.cloud.sap`

## 0.18.1 - 2025/06/12

- RabbitMQ [4.1.1 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.1.1)
  - only `4.1.x` releases are [supported](https://www.rabbitmq.com/release-information#currently-supported)
  - [4.1.1 Release Notes](https://github.com/rabbitmq/rabbitmq-server/blob/v4.1.x/release-notes/4.1.1.md)
  - faster startup with empty classic queues
  - classic queue compaction performance improvements
- Chart version bumped

## 0.18.0 - 2025/04/22

- RabbitMQ [4.1.0 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.1.0)
  * [performance improvements](https://www.rabbitmq.com/blog/2025/04/08/4.1-performance-improvements)
  * This release series supports upgrades from 4.0.x and 3.13.x
  * rabbitmqadmin has been updated to [2.0](https://github.com/rabbitmq/rabbitmqadmin-ng/releases/tag/v2.0.0), but is not yet included in the image
  * RabbitMQ nodes now provide a Prometheus histogram for message sizes published by applications
- Chart version bumped

## 0.17.2 - 2025/04/10

- RabbitMQ [4.0.8 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.0.8)
  * Fixes a number of rare replication safety issues for quorum queues
  * several cluster fixes and enhancements
- Chart version bumped

## 0.17.1 - 2025/03/19

- Set the default `max_message_size` option to pre-4.0 increased default value of 256M
  - This fixes a possible error `Failed to publish message to topic`, that might happen with RabbitMQ 4.0 and caused by an announced default value decrease
  - Metrics that will allow to make a decision about this value will be added in RabbitMQ 4.1
- Chart version bumped

## 0.17.0 - 2025/03/19

- Add [user-credential-updater](https://github.com/sapcc/rabbitmq-user-credential-updater) sidecar container
- Use sidecar container for runtime password updates
- Chart version bumped

## 0.16.1 - 2025/03/18

- RabbitMQ [4.0.7 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.0.7)
  * Classic queue message store did not remove segment files with large messages (over 4 MB) in some cases
  * Reduced memory usage and GC pressure for workloads where large (4 MB or greater) messages were published to classic queues
- chart version bumped

## 0.16.0 - 2025/03/15

- Creation of the `metrics` user with `monitoring` tag no longer coupled with enabling prometheus metrics

Native Prometheus RabbitMQ metrics don't rely on any user

To create `metrics` user, if needed, set `.Values.rabbitmq.monitoring.addMetricsUser: true`
The username for `metrics` user is taken from `.Values.rabbitmq.metrics.user`, and the password from `.Values.rabbitmq.metrics.password`

## 0.15.0

- Remove the following helm template helper functions:
  - `rabbitmq.release_host`
  - `rabbitmq.transport_url`
  - `rabbitmq._transport_url`
  - `rabbitmq.resolve_secret_urlquery`
- Chart version bumped

## 0.14.1

[@businessbean](https://github.com/businessbean)
- RabbitMQ [4.0.6 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.0.6)
  - several bugs have been fixed and improvements have been made in the server and Prometheus plugin
- chart version bumped

## 0.14.0

[@businessbean](https://github.com/businessbean)
- RabbitMQ [4.0.5 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.0.5)
- [What's new?](https://www.rabbitmq.com/docs/whats-new)
- in version [4.0.1](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v4.0.1) the default maximum message size reduced from 256 to 16MiB
  - use `customConfig.max_message_size` to set a different value if required
- chart version bumped

## 0.13.0

[@fwiesel](https://github.com/fwiesel)
- Add options to enable ssl in rabbitmq

The following options need to be set:
```yaml
enableSsl: true
certificate:
  issuerRef:
    name: <issuer-name>
externalNames:
- <optional-fqdn>
```

The default is a `ClusterIssuer`, but it can be changed with the respective value
`certificate.issuerRef.kind`

`externalNames` is optional, and specifies the SAN in the certificate.
It is imporant there, that all names entered are accepted by the certificate-issuer.

## 0.12.1

- `app` selector label returned, because deployment selector is immutable
- chart version bumped

## 0.12.0

[@businessbean](https://github.com/businessbean)
- RabbitMQ [3.13.7 Release Notes](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.13.7)
- version info added to labels
  - to allow gatekeeper rules based on them
- old (non-standard) labels removed
- note: rabbitmq statefulsets (but not deployments) need to be deleted before upgrade
- chart version bumped

### label example
```yaml
labels:
  app.kubernetes.io/name: rabbitmq
  app.kubernetes.io/instance: keystone-rabbitmq
  app.kubernetes.io/component: rabbitmq-prometheusrule-alert
  app.kubernetes.io/part-of: keystone
  app.kubernetes.io/version: 3.13.7
  app.kubernetes.io/managed-by: "helm"
  helm.sh/chart: rabbitmq-0.12.0
```

### removed labels
```yaml
labels:
   app: keystone-rabbitmq
   component: rabbitmq
   chart: "rabbitmq-0.11.1"
   release: "keystone"
   heritage: "Helm"
   system: openstack
```

### Prometheus label names that must be updated

These labels must be updated if you use them in your Prometheus alerts definitions.
- `app` must be `app_kubernetes_io_instance`
- `component` must be `app_kubernetes_io_name`

## 0.11.4

- priorityClassName updated to new naming convention and default value added

## 0.11.3

- Add linkerd opaque ports annotation for RabbitMQ deployment/statefulset and service

## 0.11.2

- Append urlquery in `rabbitmq.resolve_secret_urlquery` function for non-vault values

## 0.11.1

nathan.oyler@sap.com
- Remove alert for unacknowledged as it's been renamed unack

## 0.11.0

- Update RabbitMQ to version 3.13.6-management
- Add `helm.sh/chart` label
- `app.kubernetes.io/version` is now an application version

## 0.10.1

- add urlquery escaped transport function to the helpers to be used while switching to secret-injector

## 0.10.0

- add ability to change service type and set externalTrafficPolicy

## 0.9.0

- add pythonic escaping of special characters in the startup script
- move secrets from the startup script to /etc/rabbitmq/secrets
- disable guest user completely

## 0.8.0

- Remove support of the insecure rabbitmq-exporter sidecar container
  1. Sidecar uses plaintext credentials in environment variables
  2. Sidecar utilises Management API metrics
  3. Management API metrics will not be supported in future RabbitMQ releases

## 0.7.5

- remove shared service labels from volumeClaimTemplates, because it's immutable
- return mutable shared service labels to statefulset metadata

## 0.7.4

nathan.oyler@sap.com
- remove shared service tags for statefulsets, statefulsets are immutable.

## 0.7.3

- add option enableAllFeatureFlags to enable all stable feature flags after service has started

## 0.7.2

- Fix RabbitMQRPCUnackTotal alert to support both old and new unack metric name

## 0.7.1

birk.bohne@sap.com
- `app.kubernetes.io/component` label fixed by using the `.Chart.Name` variable instead of a hardcoded value
- defined functions are shared between all (sub)charts and because of that hardcoded values will cause unexpected behavior

## 0.6.13

dusan.dordevic@sap.com
- Adding standardized labels to all objects, according to https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels and https://helm.sh/docs/chart_best_practices/labels/

## 0.6.9

b.alkhateeb@sap.com
- update rabbitMQ to version 3.13.0-management

## 0.6.8

dusan.dordevic@sap.com
- Add /metric/detailed and /metrics/per-object prometheus endpoints. They can be enabled/disabled from values.yaml, metrics section

## 0.6.7

dusan.dordevic@sap.com
- add switch in values.yaml that allows creating user: dev / pass: dev that should be used for development only

## 0.6.6

maurice.escher@sap.com
- fix permissions if persistence is enabled, does a recursive chown once
- add owner info explicitly to pvc, clears helm diff from injected annotations

## 0.6.5

maurice.escher@sap.com
- add default container annotation, useful for `kubectl logs` or `kubectl exec`

## 0.6.4

maurice.escher@sap.com
- make start wait timeout configurable, coupled with liveness initial delay

## 0.6.3

fabian.wiesel@sap.com
- move setup script with credentials to secret

## 0.6.2

b.alkhateeb@sap.com
- new mechanism to add custom configuration file to RabbitMQ pods, under /etc/rabbitmq/conf.d/20-custom.conf
  custom configuration can be added as `key, value` pairs under .Values.customConfig
  ```
  customConfig:
    key1: value1
    key2: value2
  ```
  Any key under .Values.customConfig with null value will be ignored in the config file.

## 0.6.1

maurice.escher@sap.com
- fixing alerts to fire only if there is no RabbitMQ pods are ready

## 0.6.0

b.alkhateeb@sap.com
- build Linkerd integration for RabbitMQ Chart
  to activate/deactivate linkerd annotation please set the following (active by default)
  ```
  linkerd:
    enabled: true
  ```

## 0.5.2

b.alkhateeb@sap.com
- update rabbitmq to version 3.11.15-management (bug fixes).

## 0.5.1

fabian.wiesel@sap.common
- Use just the hostname without domain for the transport-url

## 0.5.0

b.alkhateeb@sap.com
- added a switch to activate rabbitmq-prometheus plugin instead of the side car exporter.
  to activate collect metrics with plugin please set your values to:
```
    metrics:
      port: 9150
      enabled: false
      sidecar:
        enabled: false
```
- RabbitMQ-prometheus plugin provides different naming schema of the metrics as the side car RabbitMQ exporter.
  metrics can be found: https://github.com/rabbitmq/rabbitmq-prometheus/blob/master/metrics.md
- default values still using metrics sidecar exporter

## 0.4.0

b.alkhateeb@sap.com
 - Updating rabbitmq docker image to 3.10.5-management (release note: https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.10.5).
 - using TCP socket check for the readinessProbe instead of deprecated rabbitmqctl node_health_check (resone: https://github.com/rabbitmq/cluster-operator/blob/43e7c05c4e5cf47322ef11b1b98b2bb70bf32a12/internal/resource/statefulset.go#L586-L604)
 - adding CHANGELOG
