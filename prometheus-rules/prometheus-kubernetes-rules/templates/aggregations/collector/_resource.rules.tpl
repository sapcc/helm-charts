groups:
- name: cpu
  rules:
  # TODO: remove with K8S 1.10+ / cAdvisor 0.29.0 (https://github.com/google/cadvisor/blob/master/CHANGELOG.md#0290-2018-02-20)
  - record: {{ include "prefix" . }}container_cpu_system_seconds_total
    expr: sum(container_cpu_system_seconds_total{container_name!="POD"}) by (id,namespace,pod_name,container_name)

  - record: {{ include "prefix" . }}container_cpu_usage_seconds_total
    expr: sum(container_cpu_usage_seconds_total{container_name!="POD"}) by (id,namespace,pod_name,container_name)

  - record: {{ include "prefix" . }}container_cpu_user_seconds_total
    expr: sum(container_cpu_user_seconds_total{container_name!="POD"}) by (id,namespace,pod_name,container_name)

  - record: {{ include "prefix" . }}container_cpu_saturation_ratio
      expr: sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name) / (sum(irate(aggregated:container_cpu_usage_seconds_total[5m])) by (namespace, pod_name, container_name) + sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name))

  - record: {{ include "prefix" . }}container_cpu_utilization_ratio
    expr: ( sum(irate(container_cpu_cfs_throttled_seconds_total[5m])) by (namespace, pod_name, container_name) + sum(irate(aggregated:container_cpu_usage_seconds_total[5m])) by (namespace, pod_name, container_name) ) / sum(label_join(label_join(kube_pod_container_resource_requests_cpu_cores, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: {{ include "prefix" . }}container_cpu_allocation_average
    expr: |
        avg(
            avg(
                count_over_time(container_cpu_allocation{container!="",container!="POD", node!=""}[10m])
                *
                avg_over_time(container_cpu_allocation{container!="",container!="POD", node!=""}[10m])
            ) by (namespace, container, pod, node, cluster)
        ) by (namespace, container_name, pod_name, node, cluster)

  - record: {{ include "prefix" . }}container_cpu_usage_seconds_average
    expr: |
        avg(
            rate(
                container_cpu_usage_seconds_total{container_name!="",container_name!="POD",instance!=""}[10m]
            )
        ) by (namespace, container_name, pod_name, node, cluster)

- name: memory
  rules:
  - record: {{ include "prefix" . }}container_memory_saturation_ratio
    expr: sum(container_memory_working_set_bytes) by (namespace, pod_name, container_name) / sum(label_join(label_join(kube_pod_container_resource_limits_memory_bytes, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: {{ include "prefix" . }}container_memory_utilization_ratio
    expr: sum(container_memory_working_set_bytes) by (namespace, pod_name, container_name) / sum(label_join(label_join(kube_pod_container_resource_requests_memory_bytes, "container_name", "", "container"), "pod_name", "", "pod")) by (namespace, pod_name, container_name)

  - record: {{ include "prefix" . }}container_memory_allocation_average
    expr: |
        avg(
            avg(
                count_over_time(container_memory_allocation_bytes{container!="",container!="POD", node!=""}[10m])
                *
                avg_over_time(container_memory_allocation_bytes{container!="",container!="POD", node!=""}[10m])
            ) by (namespace, container, pod, node, cluster)
        ) by (namespace, container_name, pod_name, node, cluster)

  - record: {{ include "prefix" . }}container_memory_usage_average
    expr: |
        avg(
            count_over_time(container_memory_working_set_bytes{container_name!="",container_name!="POD", instance!=""}[10m])
            *
            avg_over_time(container_memory_working_set_bytes{container_name!="",container_name!="POD", instance!=""}[10m])
        ) by (namespace, container_name, pod_name, node, cluster)
