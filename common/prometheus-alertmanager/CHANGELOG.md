## 2.0.5

* Update slack notification template
* Allow setting tolerations.

## 2.0.4

* Default Alertmanager mesh ports for TCP, UDP is now `9094`.

## 2.0.3

* Make service `type: NodePort` if `.Values.mesh.nodePort` is set. 

## 2.0.2

* Only 1 replica per default.

## 2.0.1

* Fix secret name if config provided via values.

## 2.0.0

* Init operated Prometheus Alertmanager chart.  
  Added in `v2.0.0` to avoid confusion with existing, but deprecated Alertmanager chart.
