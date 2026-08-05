{{/* Use this for policies that inspect Helm releases. */}}
{{- define "gatekeeper-policies.match-active-helm-releases" }}
kinds:
  - apiGroups: [""]
    kinds: ["Secret"]
labelSelector:
  matchExpressions:
    - { key: "owner", operator: "In", values: [ "helm" ] }
    {{/* When a Helm release is initially created, it's in status "pending-install" or "pending-upgrade". We need to
         ensure that policy violations are caught early in this status to protect against broken releases being rolled
         out. Once the objects in the release manifest have been created, the Helm release goes into status "deployed"
         until it is superseded by a newer release. */}}
    - { key: "status", operator: "In", values: [ "pending-install", "pending-upgrade", "deployed" ]}
{{- end }}

{{/* Use this only for checks that need to see Pod fields that are not visible in a PodSpec (e.g. status or owner refs). */}}
{{- define "gatekeeper-policies.match-pods-only" }}
kinds:
  - apiGroups: [""]
    kinds: ["Pod"]
{{- end }}

{{/* Use this for policies that call the traversal.find_pod() or traversal.find_container_specs() helper functions. */}}
{{- define "gatekeeper-policies.match-pods-and-pod-owners" }}
kinds:
  - apiGroups: [""]
    kinds: ["Pod"]
  - apiGroups: ["apps"]
    kinds: ["DaemonSet", "Deployment", "ReplicaSet", "StatefulSet"]
  - apiGroups: ["batch"]
    kinds: ["CronJob", "Job"]
{{- end }}
