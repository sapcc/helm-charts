Kube monitoring
---------------

Helm chart for Kubernetes Control Plane Monitoring and Metrics Collection.

The default installation contains multiple components:
- [prometheus-server](https://prometheus.io/)
- [prometheus-node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter)
- [event-exporter](../../prometheus-exporters/event-exporter)
- [fluent-bit](https://github.com/helm/charts/tree/master/stable/fluent-bit)
- [kube-state-metrics](https://github.com/helm/charts/tree/master/stable/kube-state-metrics)
- [k8s-secrets-certificate-exporter](../../prometheus-exporters/k8s-secrets-certificate-exporter)
- [ntp-exporter](../../prometheus-exporters/ntp-exporter)
- [oomkill-exporter](../../prometheus-exporters/oomkill-exporter)
- [ping-exporter](../../prometheus-exporters/ping-exporter)
- [prometheus-kubernetes-rules](../../prometheus-rules/prometheus-kubernetes-rules)
- Additional Prometheus exporters. See full list in [requirements.yaml](./requirements.yaml)

## Prometheis

This Helm chart deploys multiple types of Prometheis:
- `Collector` - Prometheus server without persistence (only Memory). Retain metrics for 1 hour. Discovers & scrapes monitoring targets in k8s cluster.
- `Frontend` -  Prometheus server with persistence. Retain metrics for 1 week. Federates from Collector Prometheus.

The `collector` is used to collect and aggregate CPU metrics of large nodes and might not be needed in all environments.
It can be disabled via [values](./values.yaml), in which case only a Prometheus with persistence and the relevant Kubernetes SD configuration is deployed.

Both Prometheis instances are based on our [prometheus-server](../prometheus-server) Helm chart to align deployment and configuration.

## Prerequisites

This chart relies on resources brought to you by the [Prometheus Operator](https://github.com/coreos/prometheus-operator).  
It may be installed using the [official helm chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).
