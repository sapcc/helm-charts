Global Prometheus for monitoring Kubernikus
------------------------------------------

This chart contains the configuration, alerts and rules for the global Kubernikus Prometheus.
The global Kubernikus Prometheus federates selected metrics from the regional Kubernikus Prometheis and stores them for 90 days.  

## Federation

Per convention all metrics prefixed with `global:` found in a regional Kubernikus Prometheus are automatically federated to the global Kubernikus Prometheus.
Moreover, all `ALERTS` and `up` metrics are federated.
Further metrics can be added as needed.
