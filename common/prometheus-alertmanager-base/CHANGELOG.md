## 3.0.2

* make version for operator customizable 

## 3.0.0

* upgrading to v0.26.0

## 2.2.8

* explicitly set version for to avoid operator assumptions

## 2.0.1

* Specify prometheus to pick up the alerts

## 2.0.0

* [Breaking change] Ingress related values changed. Configurable authentication on ingress level. Added OAUTH support.
* Optional additional ingress for API only with separate configuration.
* Ingress API version updated depending on k8s version.
* Bump Alertmanager to `v0.23.0`.

## 1.5.0

* Bump Alertmanager to `v0.22.0`.
* Move image to keppel dockerhub mirror.

## 1.4.2

* Remove `vice-president: "true"` annotation. Replaced by `kubernetes.io/tls-acme: "true"`.

## 1.4.1

* Ingress API version `extensions/v1beta1` -> `networking.k8s.io/v1beta1`.

## 1.4.0

* Upgrade alertmanager to `0.21.0`.

## 1.3.0

* Allow disabling default notification templates.

## 1.2.3

* Disable vice-president in ingress by default

## 1.2.2

* Set Chart `apiVersion: v2`.
* Added annotation triggering certificate automation: `kubernetes.io/tls-acme: "true"`. 

## 1.0.2

* Adds alert for cluster status.
* Adds Grafana dashboard.

## 1.0.1

* Adds [Prometheus alerts](./templates/alerts) for common Alertmanager errors.  
  **NOTE**: Only useful if Alertmanager is part of an HA cluster and the Prometheus evaluating the alerts sends alerts to all members of that cluster. 

## 1.0.0

* Init Helm chart that shall serve as a base for Prometheus Alertmanager instances.
