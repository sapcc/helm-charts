---
title: OpenstackMaiaPodOOMKilled
---

# OpenstackMaiaPodOOMKilled

## Problem

A Maia pod was OOM-killed, meaning it exceeded its memory limit and the kernel terminated it.

## Impact

Brief service interruption during the pod restart. If it is the only running pod, Maia is unavailable until the restart completes.

## Diagnosis

Identify the affected pod and confirm the cause:

```bash
kubectl -n maia get pods
kubectl -n maia describe pod <pod-name>
```

Look for `OOMKilled` in the `Last State` section.

Review application logs before the kill for memory-leak indicators:

```bash
kubectl -n maia logs <pod-name> --previous
```

Check memory usage trends on the [maia-overview](https://perses.{{ $labels.region }}.cloud.sap/projects/observability/dashboards/maia-overview) dashboard.

## Resolution Steps

1. If this is an isolated event with no clear cause, monitor for recurrence.
2. If OOM kills are recurring, increase the memory `limits` in the Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml) and deploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia).
3. If a memory leak is suspected in the application, escalate to the development team.
