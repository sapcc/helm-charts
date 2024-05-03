opentelemetry-operator
------------------------------

Chart for deploying opentelemetry-operator and simple collectors.

Prerequisite: opentelemetry-crds

Source: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator

As of now this chart deploys
* otel collectors to accept metrics and logs
* ServiceMonitor to scrape logs statically into prometheus infra-frontend

