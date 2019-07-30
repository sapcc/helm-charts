Prometheus exporters
--------------------

This folder contains independent Helm charts for Prometheus exporters used in the SAP Converged Cloud.

Helm charts are can be consumed via `requirements.yaml` from our Helm Chart registry:
```yaml
dependencies:
  - name: $chartName
    repository: https://charts.global.cloud.sap
    version: 0.1.0
``` 