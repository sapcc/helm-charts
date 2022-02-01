Prometheus exporters
--------------------

This folder contains independent Helm charts for Prometheus exporters used in the SAP Converged Cloud.

Helm charts are pushed to our Helm Chart registry, which can be added via:
```
helm repo add sapcc https://charts.eu-de-2.cloud.sap
```

Example `requirements.yaml` to consume the charts:

```yaml
dependencies:
  - name: $chartName
    repository: https://charts.eu-de-2.cloud.sap
    version: 0.1.0
``` 
