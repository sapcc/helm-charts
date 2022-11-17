# prometheus-monitors

This chart deploys a Pod|ServiceMonitor that contains the same relabelings which are performed when using the Prometheus scrape annotations.

This includes:

- Kubernetes Namespace
- Kubernetes Pod Name
- Labels set for the Kubernetes Pod
- Region
- Cluster
- Cluster Type [e.g. metal, scaleout, ...]

This chart is meant to serve a set of common rules for Pod|ServiceMonitors to ensure that all labels required for alert routing are appended to the scraped series.


## Usage

Add `prometheus-monitors` as a dependency to your chart's `Chart.yaml` file:

```yaml
dependencies:
  - name: prometheus-monitors
    repository: https://charts.eu-de-2.cloud.sap
    version: # use prometheus-monitors's current version from Chart.yaml
```

 then run:

```sh
helm dep update
```

## Configuration

The following table lists the configurable parameters of the `prometheus-monitors` chart and their default values.

| Parameter | Default | Description |
| ---       | ---         | ---     |
| `podMonitor.enabled` | `false` | If set to `true` it will render the PodMonitor  |
| `serviceMonitor.enabled` | `false` | If set to `true` it will render the ServiceMonitor  |
| `prometheus` | "" | Name of the Prometheus to scrape the monitor |
| `clusterType`| `controlplane` | __Note:__ In most cases this value is set via regional globals.yaml |
| `namespaces` | `[]` | Selector to select which namespaces the Kubernetes Endpoints objects are discovered from. See [NamespaceSelector](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.NamespaceSelector) |
| `matchLabels` | `[]` | Selector to select Endpoints objects see [Kubernetes meta/v1.LabelSelectors](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#labelselector-v1-meta) |
| `matchExpressions` | `[]` | Selector to select Endpoints objects see [Kubernetes meta/v1.LabelSelectors](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#labelselector-v1-meta) |
| `scrapeInterval` | `60` | Interval in seconds at which metrics should be scraped. |
| `scrapeTimeout` | `55` | Timeout in seconds after which the scrape is ended. |
| `metricsPort` | `metrics` | Name of the pod port this endpoint refers to. |
| `metricsPath` | `true` | HTTP path to scrape for metrics |
| `customRelabelings` | `[]` | RelabelConfigs to apply to samples before scraping. Prometheus Operator automatically adds relabelings for a few standard Kubernetes fields. The original scrape job’s name is available via the __tmp_prometheus_job_name label. More info: <https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config> also see [[]RelabelConfig](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.RelabelConfig) |
| `customMetricRelabelings` | `[]` | MetricRelabelConfigs to apply to samples before ingestion. see [[]RelabelConfig](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.RelabelConfig) |

### Notes

- No monitor is rendered if both "podMonitor.enabled" and "serviceMonitor.enabled" are enabled
- It may be sufficient to only configure `matchExpressions` or `matchLabels`

## Additional Documentation

- API Spec for [PodMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.PodMonitor)

- API Spec for [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor)
