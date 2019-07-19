# Prometheus rules

This folder contains independent Helm charts containing Prometheus alert- and aggregation rules specific to a cluster type.
Generic alerts and aggregations for monitoring a Kubernetes cluster can be found as part of the [kube-monitoring/kube-rules](../kube-monitoring/charts/kube-rules) helm chart.   

The structure looks like this:
```
.
└── prometheus-rules
    │
    ├── controlplane            # Baremetal controlplane specific alerts and aggregations.
    │   ├── alerts
    │   └── aggregations
    │
    ├── scaleout                # Scaleout cluster specific alerts and aggregations.
    │   ├── alerts
    │   └── aggregations
    │
   ...
```
