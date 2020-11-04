# Prometheus Pushgateway

## Prerequisite

This chart is using the official chart from [prometheus-community](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-pushgateway). Kudos for creating it. It might differ, so if you want the orignal, visit link above.

Please also check [original Chart.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-pushgateway/Chart.yaml) for original maintainers.

## General

This chart bootstraps a prometheus [pushgateway](http://github.com/prometheus/pushgateway) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

An optional prometheus `ServiceMonitor` can be enabled, should you wish to use this gateway with a [Prometheus Operator](https://github.com/coreos/prometheus-operator).

## Get Repo Info

```console
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](./values.yaml), or run these configuration commands:

```console
# Helm 2
$ helm inspect values prometheus-community/prometheus-pushgateway

# Helm 3
$ helm show values prometheus-community/prometheus-pushgateway
```
