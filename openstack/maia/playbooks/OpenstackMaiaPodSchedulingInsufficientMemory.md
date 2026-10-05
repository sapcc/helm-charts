---
title: OpenstackMaiaPodSchedulingInsufficientMemory
---

# OpenstackMaiaPodSchedulingInsufficientMemory

## Problem

A Maia pod is repeatedly failing to be scheduled due to insufficient memory on the target node.

## Impact

Maia cannot scale out. If all existing pods are healthy the service stays up, but capacity is constrained and a pod failure could cause an outage.

## Diagnosis

Check the pod status and scheduling events:

```bash
kubectl -n maia get pods
kubectl -n maia describe pod <pod-name>
```

Look for `Insufficient memory` in the events section.

Check node memory availability across the cluster:

```bash
kubectl describe nodes | grep -A5 "Allocated resources"
```

## Resolution Steps

1. If no nodes have sufficient memory, coordinate with the infrastructure team to add capacity.
2. If memory `requests` are set higher than the workload requires, adjust them in the Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml) and deploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia).
3. Monitor the pod until it successfully schedules.
