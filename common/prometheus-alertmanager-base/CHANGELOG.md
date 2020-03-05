## 1.0.2

* Adds alert for cluster status.
* Adds Grafana dashboard.

## 1.0.1

* Adds [Prometheus alerts](./templates/alerts) for common Alertmanager errors.  
  **NOTE**: Only useful if Alertmanager is part of an HA cluster and the Prometheus evaluating the alerts sends alerts to all members of that cluster. 

## 1.0.0

* Init Helm chart that shall serve as a base for Prometheus Alertmanager instances.
