# Content of this directory

- `Chart.yaml`, `templates/configmap.yaml` and `values.yaml`: a very minimal helm chart
- `helm-release.yaml`: installed Chart and dumped secret via the following commands ``helm install almost-empty-chart . && kubectl get secret sh.helm.release.v1.almost-empty-chart.v1 -o yaml > helm-release.yaml``
