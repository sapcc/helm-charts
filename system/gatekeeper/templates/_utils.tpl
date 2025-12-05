{{- define "match_active_helm_releases" }}
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
{{- end -}}

{{/* This match expression is only for checks that need to see Pod fields that are not visible in a PodSpec (e.g. status or owner refs). */}}
{{- define "match_pods_only" }}
kinds:
  - apiGroups: [""]
    kinds: ["Pod"]
{{- end -}}

{{/* Use this for policies that call the traversal.find_pod() or traversal.find_container_specs() helper function. */}}
{{- define "match_pods_and_pod_owners" }}
kinds:
  - apiGroups: [""]
    kinds: ["Pod"]
  - apiGroups: ["apps"]
    kinds: ["DaemonSet", "Deployment", "ReplicaSet", "StatefulSet"]
  - apiGroups: ["batch"]
    kinds: ["CronJob", "Job"]
{{- end }}

{{/* This generates annotations that the DOOP dashboard reads to link back to the source code of constraint templates and constraints. */}}
{{- define "sources" }}
template-source:   'https://github.com/sapcc/helm-charts/tree/master/system/gatekeeper/templates/constrainttemplate-{{ index . 0 }}.yaml'
constraint-source: 'https://github.com/sapcc/helm-charts/tree/master/system/gatekeeper-config/templates/constraint-{{ index . 1 }}.yaml'
{{- end }}

{{/* This generates an annotation containing the constraint's docstring. */}}
{{- define "docstring" }}
docstring: {{ (index . 0).Files.Get (printf "files/%s.md" (index . 1)) | toJson }}
{{- end }}
