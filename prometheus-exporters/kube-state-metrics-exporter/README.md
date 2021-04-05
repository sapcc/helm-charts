kube-state-metrics-exporter
---------------------------

Collects metrics from the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) and provides additional, aggregated metrics to reduce duplication of PromQL expressions.  
Moreover, labels that are specific to the kube-state-metrics deployment like instance, pod_name, etc. are dropped to avoid flapping alerts based on these.  
Available metrics can be seen [here](./aggregations/aggregations.rules).

## Requirements

- At least one instance of kube-state-metrics.
- The [Prometheus operator](https://github.com/coreos/prometheus-operator) and its custom resources.

## Usage

Set the mandatory values:

```
# Name of the Prometheus to which the Prometheus Operator shall assign the ServiceMonitor and recording rules.
prometheusName: $name
```
