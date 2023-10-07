This check finds containers that do not have CPU and memory requests configured.

#### Why is this a problem?

The pod scheduler relies on resource requests to decide where to place newly created pods. If resource requests are
missing or not accurate, pods could end up on nodes that do not have enough resources for them to run properly.
We have already had API outages because of this.

#### How to fix?

Configure requests and limits for "cpu" and "memory" as described in [this article][doc]. Choose values based on
historical usage, by looking at the `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes` metrics
in prometheus-kubernetes. The Grafana dashboard [Container Resources][dashboard] shows these metrics in the "CPU Usage"
and "Memory Usage" panels. **Set the memory request equal to the memory limit to avoid unexpected scheduling behavior.**
For CPU, request and limit can and should diverge: The request represents the baseline load, the limit encompasses all
expected spikes.

[doc]: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
[dashboard]: https://grafana.eu-de-1.cloud.sap/d/kubernetes-container-resources/kubernetes-container-resources

