# Changelog

## 0.1.0

- add support for additionalEndpoints. These additional endpoints are configured like the main endpoint, but under the `additionalEndpoints` key. This allows for the configuration of multiple endpoints for a single Pod|ServiceMonitor.

## 0.0.2

- drops default suffix from name of Pod|ServiceMonitor
- adds explicit error for ServiceMonitor without selector
- adds option to specify JobLabel
- adds `prometheus-monitor-version` label for tracking of chart usage
- adds templating for basicAuth
- fixes to ServiceMonitor template

## 0.0.1

- initial release
