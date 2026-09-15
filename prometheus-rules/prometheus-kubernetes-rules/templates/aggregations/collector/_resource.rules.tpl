groups:
- name: cpu
  rules:
  - record: container_cpu_saturation_ratio
    expr: |
        sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name)
        /
        (sum(irate(container_cpu_usage_seconds_total[5m])) by (namespace, pod_name, container_name) + sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name))

  - record: container_cpu_utilization_ratio
    expr: |
        ( sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name) + sum(irate(container_cpu_usage_seconds_total[5m])) by (namespace, pod_name, container_name) )
        /
        sum(label_join(label_join(kube_pod_container_resource_requests{resource="cpu"}, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: container_cpu_usage_seconds_average
    expr: |
        avg(
            rate(
                container_cpu_usage_seconds_total{container_name!="",instance!=""}[10m]
            )
        ) by (namespace, container_name, pod_name, node, cluster)

- name: memory
  rules:
  - record: container_memory_saturation_ratio
    expr: |
        sum(container_memory_working_set_bytes) by (namespace, pod_name, container_name)
        /
        sum(label_join(label_join(kube_pod_container_resource_limits{resource="memory"}, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: container_memory_utilization_ratio
    expr: |
        sum(container_memory_working_set_bytes) by (namespace, pod_name, container_name)
        /
        sum(label_join(label_join(kube_pod_container_resource_requests{resource="memory"}, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: container_memory_usage_average
    expr: |
        avg(
            count_over_time(container_memory_working_set_bytes{container_name!="",instance!=""}[10m])
            *
            avg_over_time(container_memory_working_set_bytes{container_name!="",instance!=""}[10m])
        ) by (namespace, container_name, pod_name, node, cluster)
