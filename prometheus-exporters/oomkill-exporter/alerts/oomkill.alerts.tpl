groups:
- name: oomkill.alerts
  rules:
  - alert: PodOOMKilled
    # NOTE: limes-collect-ccloud has a known small-scale memory leak and tends to crash a few times per day. I don't care about this, as long as it's still doing its job. -- @majewsky
    expr: sum by (namespace, pod_name, label_ccloud_support_group) (changes(klog_pod_oomkill{pod_name!~"limes-collect-.*"}[1d]) > 0 or ((klog_pod_oomkill == 1) unless (klog_pod_oomkill offset 1d == 1))) * on(pod_name, namespace) group_left(label_ccloud_support_group, label_ccloud_service) (max by(pod_name, namespace, label_ccloud_support_group, label_ccloud_service) (label_replace(kube_pod_labels, "pod_name", "$1", "pod", "(.*)")))
    for: 5m
    labels:
      tier: k8s
      service: {{ include "serviceFromLabelsOrDefault" "resources" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: memory
      meta: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} OOMKilled"
      playbook: 'docs/support/playbook/kubernetes/k8s_pod_oomkilled'
      no_alert_on_absence: "true" # the underlying metric is only generated after the first oomkill
    annotations:
      summary: Pod was oomkilled recently
      description: The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} was hit at least once by the oom killer within 24h

  - alert: PodConstantlyOOMKilled
    expr: (sum(changes(klog_pod_oomkill[30m])) by (namespace, pod_name, label_ccloud_support_group, label_ccloud_service) > 2) * on(pod_name, namespace) group_left(label_ccloud_support_group, label_ccloud_service) (max by(pod_name, namespace, label_ccloud_support_group, label_ccloud_service) (label_replace(kube_pod_labels, "pod_name", "$1", "pod", "(.*)")))
    for: 5m
    labels:
      tier: k8s
      service: {{ include "serviceFromLabelsOrDefault" "resources" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: memory
      meta: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} constantly OOMKilled"
      playbook: 'docs/support/playbook/kubernetes/k8s_pod_oomkilled'
      no_alert_on_absence: "true" # the underlying metric is only generated after the first oomkill
    annotations:
      summary: Pod was oomkilled more than 2 times in 30 minutes
      description: The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} killed several times in short succession. This could be due to wrong resource limits.
