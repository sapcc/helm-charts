Rabbitmq CHANGELOG
==============

This file is used to list changes made in each version of the common chart rabbitmq.

0.7.1
------
birk.bohne@sap.com
- `app.kubernetes.io/component` label fixed by using the `.Chart.Name` variable instead of a hardcoded value
- defined functions are shared between all (sub)charts and because of that hardcoded values will cause unexpected behavior

0.6.13
------
dusan.dordevic@sap.com
-Adding standardized labels to all objects, according to https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels and https://helm.sh/docs/chart_best_practices/labels/

0.6.9
-----
b.alkhateeb@sap.com
- update rabbitMQ to version 3.13.0-management

0.6.8
-----
dusan.dordevic@sap.com
- Add /metric/detailed and /metrics/per-object prometheus endpoints. They can be enabled/disabled from values.yaml, metrics section

0.6.7
-----
dusan.dordevic@sap.com
- add switch in values.yaml that allows creating user: dev / pass: dev that should be used for development only

0.6.6
-----
maurice.escher@sap.com
- fix permissions if persistence is enabled, does a recursive chown once
- add owner info explicitly to pvc, clears helm diff from injected annotations

0.6.5
-----
maurice.escher@sap.com
- add default container annotation, useful for `kubectl logs` or `kubectl exec`

0.6.4
-----
maurice.escher@sap.com
- make start wait timeout configurable, coupled with liveness initial delay

0.6.3
-----
fabian.wiesel@sap.com
- move setup script with credentials to secret

0.6.2
-----
b.alkhateeb@sap.com
- new mechanism to add custom configuration file to RabbitMQ pods, under /etc/rabbitmq/conf.d/20-custom.conf
  custom configuration can be added as `key, value` pairs under .Values.customConfig
  ```
  customConfig:
    key1: value1
    key2: value2
  ```
  Any key under .Values.customConfig with null value will be ignored in the config file.

0.6.1
-----
maurice.escher@sap.com
- fixing alerts to fire only if there is no RabbitMQ pods are ready

0.6.0
-----
b.alkhateeb@sap.com
- build Linkerd integration for RabbitMQ Chart
  to activate/deactivate linkerd annotation please set the following (active by default)
  ```
  linkerd:
    enabled: true
  ```

0.5.2
-----
b.alkhateeb@sap.com
- update rabbitmq to version 3.11.15-management (bug fixes).

0.5.1
-----
fabian.wiesel@sap.common
- Use just the hostname without domain for the transport-url

0.5.0
-----
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

0.4.0
-----
b.alkhateeb@sap.com
 - Updating rabbitmq docker image to 3.10.5-management (release note: https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.10.5).
 - using TCP socket check for the readinessProbe instead of deprecated rabbitmqctl node_health_check (resone: https://github.com/rabbitmq/cluster-operator/blob/43e7c05c4e5cf47322ef11b1b98b2bb70bf32a12/internal/resource/statefulset.go#L586-L604)
 - adding CHANGELOG

==============
