Kubernetes secrets certificate exporter
---------------------------------------

Installs the [Kubernetes secrets certificate exporter](https://github.com/sapcc/k8s-secrets-certificate-exporter) which exports expiry metrics for certificates found in kubernetes secrets.  
Also contains [Prometheus alerts](./templates/alerts/_cert-expiry.alerts.tpl) for expiring certificates.

## Configuration

See [values](./values.yaml).
