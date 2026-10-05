---
title: OpenstackMaiaResponsiveness
---

# OpenstackMaiaResponsiveness

## Problem

The Maia API 99th-percentile response time has exceeded 3 seconds for the past hour. Tenants are experiencing slow metric queries.

## Impact

Tenant PromQL queries and dashboard loads are slow. The service is degraded but not fully unavailable.

## Diagnosis

1. Review the [maia-overview](https://perses.<region>.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for request latency trends and identify which handler is slow (`query`, `query_range`, `federate`, etc.).

2. Check whether the underlying Prometheus is under heavy load (see also `OpenstackMaiaPrometheusAvail`):
   ```bash
   kubectl -n maia get pods | grep prometheus
   kubectl -n maia top pod <prometheus-pod>
   ```

3. Check Maia API pod resource usage:
   ```bash
   kubectl -n maia top pods
   ```

## Resolution Steps

1. If high CPU throttling is observed on the API pod, increase resource limits in the Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml) and deploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia).
2. If the Prometheus backend is saturated, check for runaway federation scrapes or unusually large queries from tenants.
3. If latency persists after resource changes, contact the development team.
