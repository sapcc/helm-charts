{{/*
Named templates for each RBAC/SA resource. Each template accepts a plain dict so
callers can control namespace without duplicating rule definitions:

  Local (non-remote): include "disco.X" (dict "namespace" .Release.Namespace "serviceAccountName" .Values.serviceAccount.name)
  Shoot  (remote):    include "disco.X" (dict "namespace" "kube-system"       "serviceAccountName" .Values.serviceAccount.name)

ClusterRoles have no namespace or SA reference, so they accept any context (. is fine).
*/}}

{{- define "disco.serviceAccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ index . "serviceAccountName" }}
  namespace: {{ index . "namespace" }}
{{- end }}

{{- define "disco.clusterRole.manager" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: {{ .Release.Name }}-manager-role
rules:
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - disco.stable.sap.cc
  resources:
  - records
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - disco.stable.sap.cc
  resources:
  - records/finalizers
  verbs:
  - update
- apiGroups:
  - disco.stable.sap.cc
  resources:
  - records/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
{{- end }}

{{- define "disco.clusterRoleBinding.manager" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ index . "releaseName" }}-manager-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ index . "releaseName" }}-manager-role
subjects:
- kind: ServiceAccount
  name: {{ index . "serviceAccountName" }}
  namespace: {{ index . "namespace" }}
{{- end }}

{{- define "disco.role.leaderElection" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: disco-leader-election-role
  namespace: {{ index . "namespace" }}
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
{{- end }}

{{- define "disco.roleBinding.leaderElection" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: disco-leader-election-rolebinding
  namespace: {{ index . "namespace" }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: disco-leader-election-role
subjects:
- kind: ServiceAccount
  name: {{ index . "serviceAccountName" }}
  namespace: {{ index . "namespace" }}
{{- end }}

{{- define "disco.clusterRole.proxy" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .Release.Name }}-proxy-role
rules:
- apiGroups:
  - authentication.k8s.io
  resources:
  - tokenreviews
  verbs:
  - create
- apiGroups:
  - authorization.k8s.io
  resources:
  - subjectaccessreviews
  verbs:
  - create
{{- end }}

{{- define "disco.clusterRoleBinding.proxy" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ index . "releaseName" }}-proxy-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ index . "releaseName" }}-proxy-role
subjects:
- kind: ServiceAccount
  name: {{ index . "serviceAccountName" }}
  namespace: {{ index . "namespace" }}
{{- end }}

{{- define "disco.clusterRole.metricsReader" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .Release.Name }}-metrics-reader
rules:
- nonResourceURLs:
  - /metrics
  verbs:
  - get
{{- end }}

{{/*
shootRBAC assembles all RBAC resources and the ServiceAccount for the remote (shoot)
cluster. Rendered into a ManagedResource Secret so Gardener's ResourceManager applies
them. All namespaced resources are fixed to kube-system — that is where Gardener's
token-requestor looks up the ServiceAccount on the shoot cluster.
*/}}
{{- define "disco.shootRBAC" -}}
{{- $ctx := dict "namespace" .Values.remote.shootNamespace "serviceAccountName" .Values.serviceAccount.name "releaseName" .Release.Name }}
{{ include "disco.serviceAccount" $ctx }}
---
{{ include "disco.clusterRole.manager" . }}
---
{{ include "disco.clusterRoleBinding.manager" $ctx }}
---
{{ include "disco.role.leaderElection" $ctx }}
---
{{ include "disco.roleBinding.leaderElection" $ctx }}
---
{{ include "disco.clusterRole.proxy" . }}
---
{{ include "disco.clusterRoleBinding.proxy" $ctx }}
---
{{ include "disco.clusterRole.metricsReader" . }}
{{- end }}
