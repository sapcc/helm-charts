OpenStack Prometheus
--------------------

Exactly that. A Prometheus for monitoring OpenStack components.

## Scraping metrics

Monitoring targets may be configured statically or be discovered dynamically using Prometheus' service discovery.  
A Kubernetes resource (e.g. pod, service, etc.) is only considered when it has the following annotations:
```
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/targets: "openstack"
```

## Alerting and Aggregation rules

Alerts and aggregation rules are provided via a `PrometheusRule` CRD and shall be assigned to this Prometheus by adding  
```
metadata:
  labels:
    prometheus: openstack
```
