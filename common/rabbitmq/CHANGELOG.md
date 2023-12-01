Rabbitmq CHANGELOG
==============

This file is used to list changes made in each version of the common chart rabbitmq.


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
