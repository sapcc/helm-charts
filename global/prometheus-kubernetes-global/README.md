Global Prometheus for monitoring Kubernetes
------------------------------------------

This chart contains the configuration, alerts and rules for the global Kubernetes Prometheus.
The global Kubernetes Prometheus federates selected metrics from the regional Kubernetes Prometheis and stores them for 90 days.  

## Federation

Per convention all metrics prefixed with `global:` are automatically federated from the regional Kubernetes Prometheis. Moreover, all `ALERTS` and `up` metrics are federated.
Further metrics can be added via [values](.values.yaml) as needed.
