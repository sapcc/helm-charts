Prometheus Alerts
-----------------

This folder contains a set of basic alerts for the Prometheus server which are deployed via the PrometheusRule custom resource.  
They will only be active if one alertmanager is configured via `.Values.alertmanagers`.  

Additional alerts for [Thanos components](./../thanos/README.md) will be deployed if it's enabled via `.Values.thanos.enabled`.

Alerts are structured by `tier`, which can be provided via `.Values.global.tier`, `Values.alerts.tier`.
