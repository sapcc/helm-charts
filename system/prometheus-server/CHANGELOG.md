## v1.0.14

* Allow setting complete hostname via `.Values.ingress.hostNameOverride`

## v1.0.13

* Allow setting additional annotations on ingress.

## v1.0.12

* Fix missing base64 encoding of alertmanager configuration.

## v1.0.11

* Update to prom/prometheus:v2.9.1

## v1.0.10

* Add tolerations.

## v1.0.8

* Add out-of-the-box service discovery for endpoints, services.

## v1.0.7

* Add configurable security context.

## v1.0.6

* Add option to inject additional configmaps to a prometheus instance via `.Values.configMaps`.
* Add option to specify list of alertmanagers via `.Values.alertmanagers`.
