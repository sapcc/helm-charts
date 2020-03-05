# Prometheus rules

This folder contains independent Helm charts for Prometheus alert- and aggregation rules used in the SAP Converged Cloud.  

**Note**: This folder is for a very specific subset of alerts only. The majority of Prometheus alert- and aggregation rules should be deployed alongside the application that is generating them.

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
