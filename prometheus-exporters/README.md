Prometheus exporters
--------------------

This folder contains independent Helm charts for Prometheus exporters used in the SAP Converged Cloud.

Helm charts are pushed to our Helm Chart registry, which can be added via:
```
helm repo add sapcc oci://keppel.eu-de-1.cloud.sap/ccloud-helm
```

Example `requirements.yaml` to consume the charts:

```yaml
dependencies:
  - name: $chartName
    repository: oci://keppel.eu-de-1.cloud.sap/ccloud-helm
    version: 0.1.0
``` 
