---
title: MaiaPrometheusFederationDown
---

# MaiaPrometheusFederationDown

## Problem

One or more Prometheus federation targets that Maia scrapes via federation are down. The metrics from that source are missing from Maia.

Affected sources include: `prometheus-openstack`, `prometheus-infra-collector`, `prometheus-vmware-*`, `cronus-reputation-statistics`.

## Impact

Tenants cannot query metrics that originate from the affected federation source. Other metric sources remain available.

## Diagnosis

Identify the affected federation target from the alert label `exported_job`.

Check the health of the corresponding Prometheus instance:

```bash
kubectl get pods -A | grep <exported-job-name>
```

Review the [maia-overview](https://perses.<region>.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for federation scrape health.

## Resolution Steps

1. If the source Prometheus is down, coordinate with the team responsible for that instance to restore it.
2. If the source Prometheus is healthy but the federation scrape is failing, check network connectivity between the `maia` namespace and the source namespace.
3. Verify the Maia Prometheus scrape configuration includes the correct federation URL and credentials.
4. If the issue cannot be resolved locally, contact the development team.
