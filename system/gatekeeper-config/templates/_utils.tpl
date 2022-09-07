{{- define "match_active_helm_releases" }}
kinds:
  - apiGroups: [""]
    kinds: ["Secret"]
labelSelector:
  matchExpressions:
    - { key: "owner", operator: "In", values: [ "helm" ] }
    {{/* When a Helm release is initially created, it's in status "pending-upgrade". We need to ensure that policy
         violations are caught early in this status to protect against broken releases being rolled out. Once the
         objects in the release manifest have been created, the Helm release goes into status "deployed" until it is
         superseded by a newer release. */}}
    - { key: "status", operator: "In", values: [ "pending-upgrade", "deployed" ]}
{{- end -}}

{{/* This match expression is only for checks that need to see the "status" section of the Pod. */}}
{{- define "match_pods_only" }}
kinds:
  - apiGroups: [""]
    kinds: ["Pod"]
{{- end -}}
