This check finds containers that do not have CPU and memory limits configured.

#### Why is this a problem?

Such containers could use an unbounded amount of resources (for example, because of a memory leak). Those resources
would then not be available to other (potentially more important) containers running on the same node. We have already
had API outages because of this.

#### How to fix?

Configure requests and limits for "cpu" and "memory" as described in [this article][doc]. Choose values based on
historical usage, by looking at the `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes` metrics
in prometheus-kubernetes. The Grafana dashboard [Container Resources][dashboard] shows these metrics in the "CPU Usage"
and "Memory Usage" panels. **Set the memory request equal to the memory limit to avoid unexpected scheduling behavior.**
For CPU, request and limit can and should diverge: The request represents the baseline load, the limit encompasses all
expected spikes.

[doc]: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
[dashboard]: https://grafana.eu-de-1.cloud.sap/d/kubernetes-container-resources/kubernetes-container-resources
