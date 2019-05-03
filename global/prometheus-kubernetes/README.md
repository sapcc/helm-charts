Global Prometheus for monitoring Kubernetes
------------------------------------------

This chart contains the configuration, alerts and rules for the global Kubernetes Prometheus.
The global Kubernetes Prometheus federates selected metrics from the regional Kubernetes Prometheis and stores them for 90 days.  

## Federation

Per convention all metrics prefixed with `global:` found in a regional Kubernetes Prometheus are automatically federated to the global Kubernetes Prometheus.
Moreover, all `ALERTS` and `up` metrics are federated.
Further metrics can be added as needed.
