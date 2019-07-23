# Prometheus rules

This folder contains independent Helm charts for Prometheus alert- and aggregation rules used in the SAP Converged Cloud. 

The structure looks like this:
```
.
└── prometheus-rules
    │
    ├── controlplane            # Baremetal controlplane specific alerts and aggregations.
    │   ├── alerts
    │   └── aggregations
    │
    ├── kubernetes              # Kubernetes alert and aggregations.
    │   ├── alerts
    │   └── aggregations
    │
    ├── scaleout                # Scaleout cluster specific alerts and aggregations.
    │   ├── alerts
    │   └── aggregations
    │
   ...
```
