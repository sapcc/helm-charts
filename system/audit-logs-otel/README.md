---
title: Audit Logs Plugin
---

Learn more about the **Audit Logs** Plugin. Use it to enable the ingestion, collection and export of telemetry signals (logs and metrics) for your Greenhouse cluster.

The main terminologies used in this document can be found in [core-concepts](https://cloudoperators.github.io/greenhouse/docs/getting-started/core-concepts).

## Overview

OpenTelemetry is an observability framework and toolkit for creating and managing telemetry data such as metrics, logs and traces. Unlike other observability tools, OpenTelemetry is vendor and tool agnostic, meaning it can be used with a variety of observability backends, including open source tools such as _OpenSearch_ and _Prometheus_.

The focus of the Plugin is to provide easy-to-use configurations for common use cases of receiving, processing and exporting telemetry data in Kubernetes. The storage and visualization of the same is intentionally left to other tools.

Components included in this Plugin:

- [Collector](https://github.com/open-telemetry/opentelemetry-collector)
- [Receivers](https://github.com/open-telemetry/opentelemetry-collector/blob/main/receiver/README.md)
    - [Filelog Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/filelogreceiver)
    - [k8sevents Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/k8seventsreceiver)
    - [journald Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/journaldreceiver)
    - [prometheus/internal](https://opentelemetry.io/docs/collector/internal-telemetry/)
- [Connector](https://opentelemetry.io/docs/collector/building/connector/)
- [OpenSearch Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/opensearchexporter)

## Architecture

![OpenTelemetry Architecture](img/otel-arch.png)

## Note

It is the intention to add more configuration over time and contributions of your very own configuration is highly appreciated. If you discover bugs or want to add functionality to the Plugin, feel free to create a pull request.

## Quick Start

This guide provides a quick and straightforward way to use **OpenTelemetry** for Logs as a Greenhouse Plugin on your Kubernetes cluster.

**Prerequisites**

- A running and Greenhouse-onboarded Kubernetes cluster. If you don't have one, follow the [Cluster onboarding](https://cloudoperators.github.io/greenhouse/docs/user-guides/cluster/onboarding) guide.
- For logs, a OpenSearch instance to store. If you don't have one, reach out to your observability team to get access to one.
- We recommend a running cert-manager in the cluster before installing the **Logs** Plugin
- To gather metrics, you **must** have a Prometheus instance in the onboarded cluster for storage and for managing Prometheus specific CRDs. If you don not have an instance, install the [kube-monitoring](https://cloudoperators.github.io/greenhouse/docs/reference/catalog/kube-monitoring) Plugin first.
- The **Audit Logs** Plugin currently requires the OpenTelemetry Operator bundled in the **Logs Plugin** to be installed in the same cluster beforehand. This is a technical limitation of the **Audit Logs** Plugin and will be removed in future releases.

**Step 1:**

You can install the `Logs` package in your cluster by installing it with [Helm](https://helm.sh/docs/helm/helm_install) manually or let the Greenhouse platform lifecycle do it for you automatically. For the latter, you can either:
  1. Go to Greenhouse dashboard and select the **Logs** Plugin from the catalog. Specify the cluster and required option values.
  2. Create and specify a `Plugin` resource in your Greenhouse central cluster according to the [examples](#examples).

**Step 2:**

The package will deploy the OpenTelemetry collectors and auto-instrumentation of the workload. By default, the package will include a configuration for collecting metrics and logs. The log-collector is currently processing data from the [preconfigured receivers](#Overview):
- Files via the Filelog Receiver
- Kubernetes Events from the Kubernetes API server
- Journald events from systemd journal
- its own metrics

Based on the backend selection the telemetry data will be exporter to the backend.

## Failover Connector

The **Logs** Plugin comes with a [Failover Connector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/failoverconnector) for OpenSearch for two users. The connector will periodically try to establish a stable connection for the prefered user (`failover_username_a`) and in case of a failed try, the connector will try to establish a connection with the fallback user (`failover_username_b`). This feature can be used to secure the shipping of logs in case of expiring credentials or password rotation.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auditLogs.cluster | string | `nil` | Cluster label for Logging |
| auditLogs.collectorImage.repository | string | `"ghcr.io/cloudoperators/opentelemetry-collector-contrib"` | overrides the default image repository for the OpenTelemetry Collector image. |
| auditLogs.collectorImage.tag | string | `"5b6e153"` | overrides the default image tag for the OpenTelemetry Collector image. |
| auditLogs.customLabels | string | `nil` | Custom labels to apply to all OpenTelemetry related resources |
| auditLogs.openSearchLogs.endpoint | string | `nil` | Endpoint URL for OpenSearch |
| auditLogs.openSearchLogs.failover | object | `{"enabled":true}` | Activates the failover mechanism for shipping logs using the failover_username_band failover_password_b credentials in case the credentials failover_username_a and failover_password_a have expired. |
| auditLogs.openSearchLogs.failover_password_a | string | `nil` | Password for OpenSearch endpoint |
| auditLogs.openSearchLogs.failover_password_b | string | `nil` | Second Password (as a failover) for OpenSearch endpoint |
| auditLogs.openSearchLogs.failover_username_a | string | `nil` | Username for OpenSearch endpoint |
| auditLogs.openSearchLogs.failover_username_b | string | `nil` | Second Username (as a failover) for OpenSearch endpoint |
| auditLogs.openSearchLogs.index | string | `nil` | Name for OpenSearch index |
| auditLogs.prometheus.additionalLabels | object | `{}` | Label selectors for the Prometheus resources to be picked up by prometheus-operator. |
| auditLogs.prometheus.podMonitor | object | `{"enabled":false}` | Activates the service-monitoring for the Logs Collector. |
| auditLogs.prometheus.rules | object | `{"additionalRuleLabels":null,"annotations":{},"create":true,"disabled":[],"labels":{}}` | Default rules for monitoring the opentelemetry components. |
| auditLogs.prometheus.rules.additionalRuleLabels | string | `nil` | Additional labels for PrometheusRule alerts. |
| auditLogs.prometheus.rules.annotations | object | `{}` | Annotations for PrometheusRules. |
| auditLogs.prometheus.rules.create | bool | `true` | Enables PrometheusRule resources to be created. |
| auditLogs.prometheus.rules.disabled | list | `[]` | PrometheusRules to disable. |
| auditLogs.prometheus.rules.labels | object | `{}` | Labels for PrometheusRules. |
| auditLogs.prometheus.serviceMonitor | object | `{"enabled":false}` | Activates the pod-monitoring for the Logs Collector. |
| auditLogs.region | string | `nil` | Region label for Logging |
| commonLabels | string | `nil` | Common labels to apply to all resources |

### Examples

TBD
