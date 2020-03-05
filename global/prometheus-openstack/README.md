Global Prometheus for monitoring OpenStack
------------------------------------------

This chart contains the configuration, alerts and rules for the global OpenStack Prometheus.
The global OpenStack Prometheus federates selected metrics from the regional OpenStack Prometheis and stores them for 90 days.  

## Federation

Per convention all metrics prefixed with `global:` found in a regional OpenStack Prometheus are automatically federated to the global OpenStack Prometheus.
Moreover, all `ALERTS` and `up` metrics are federated.
Further metrics can be added as needed.
