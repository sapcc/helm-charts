Alertmanager Alerts
-----------------

This folder contains a set of basic alerts for the Prometheus Alertmanager which are deployed via the PrometheusRule custom resource.  

## Requirements

Alertmanager HA cluster to ensure at least a single operational Alertmanager capable of dispatching alerts to the respective channels.  
Moreover, the Prometheus evaluating the alerts must be configured to send it's alerts to all members of the Alertmanager cluster.
