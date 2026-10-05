---
title: OpenstackMaiaExportersLag
---

# OpenstackMaiaExportersLag

## Problem

A Maia federation source's scrape duration is growing and is predicted to exceed 60 seconds within 7 days. If the scrape cycle exceeds the configured scrape interval, Maia cannot keep up and tenant metric data becomes stale.

## Impact

No immediate impact, but metric freshness will degrade if left unaddressed. At the limit, Maia will serve increasingly stale data for the affected federation source.

## Diagnosis

Identify the affected federation job from the alert label `{{ $labels.exported_job }}`.

Review the [maia-overview](https://perses.{{ $labels.region }}.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for scrape duration trends.

Check logs of the Maia Prometheus pod for slow scrape or timeout messages:

```bash
kubectl -n maia logs <prometheus-maia-oprom-pod> --since=1h | grep -i "slow\|timeout\|error"
```

## Resolution Steps

1. If the federation source itself is slow, coordinate with the team responsible for that Prometheus (e.g., `prometheus-openstack`, `prometheus-infra-collector`, `prometheus-vmware`).
2. If Maia is scraping too many series from a federation source, consider reducing the match selectors in the Helm chart scrape configuration.
3. If the scrape interval is too tight for the data volume, increase it in [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml) and deploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia).
4. If the issue cannot be resolved locally, contact the development team.
