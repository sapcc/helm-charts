# Prometheus StatsD Exporter

This chart bootstraps a prometheus [statsd exporter](https://github.com/prometheus/statsd_exporter) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The chart is a lightweight version of the [original chart](https://github.com/hahow/prometheus-statsd-exporter) and slightly adjusted to the Converged Cloud. 

## Installation

    helm3 upgrade statsd-exporter helm-charts/prometheus-exporters/statsd-exporter --install --namespace cc3test --timeout 300s --values secrets/scaleout/s-na-us-3/values/statsd-exporter.yaml
