---
title: OpenstackMaiaPodOOMExceedingLimits
---

# OpenstackMaiaPodOOMExceedingLimits

## Problem

A pod's memory usage is above 70% of its limit and is trending toward exceeding the limit within 8 hours. An OOM kill is predicted if nothing changes.

## Impact

No immediate customer impact, but an OOM kill is imminent. Acting now avoids a brief service interruption.

## Diagnosis

Check current memory saturation for all Maia pods:

```bash
kubectl -n maia top pods
```

Review the [maia-overview](https://perses.{{ $labels.region }}.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for the memory trend of the specific pod.

## Resolution Steps

1. Increase memory `limits` in the Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml) and deploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia) before the OOM kill occurs.
2. Monitor after deployment to confirm memory usage stabilizes below the new limit.
3. If memory usage continues to grow without bound, escalate to the development team as a potential memory leak.
