Global Prometheus for monitoring the infrastructure
---------------------------------------------------

This chart contains the configuration, alerts and rules for the global Infra Prometheus.
The global Infra Prometheus federates selected metrics from the regional Infra Prometheis and stores them for 90 days.  

## Federation

Per convention all metrics prefixed with `global:` found in a regional Infra Prometheus are automatically federated to the global Infra Prometheus.
Moreover, all `ALERTS` and `up` metrics are federated.
Further metrics can be added as needed.
