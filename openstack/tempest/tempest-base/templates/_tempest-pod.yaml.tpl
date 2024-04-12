{{- define "tempest-base.tempest_pod" }}
{{- if .Values.tempestKubectlAccess }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Chart.Name }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ .Chart.Name }}
rules:
- apiGroups:
  - extensions
  - apps
  resources:
  - deployments
  verbs:
  - get
  - list
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
- apiGroups:
  - ""
  resources:
  - "pods/exec"
  verbs:
  - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ .Chart.Name }}
subjects:
- kind: ServiceAccount
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace }}
roleRef:
  kind: Role
  name: {{ .Chart.Name }}
  apiGroup: rbac.authorization.k8s.io
{{- end }}
---
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Chart.Name }}
  labels:
    system: openstack
    type: configuration
spec:
  restartPolicy: Never
  {{- if .Values.tempestKubectlAccess }}
  serviceAccountName: {{ .Chart.Name }}
  {{- end }}
  containers:
    - name: {{ .Chart.Name }}
      image: {{ default "keppel.eu-de-1.cloud.sap/ccloud" .Values.global.registry}}/{{ default .Chart.Name (index .Values (print .Chart.Name | replace "-" "_")).tempest.imageNameOverride }}-plugin-python3:{{ default "latest" (index .Values (print .Chart.Name | replace "-" "_")).tempest.imageTag}}
      command:
        - kubernetes-entrypoint
      env:
        - name: COMMAND
          value: "/container.init/tempest-start-and-cleanup.sh"
        - name: NAMESPACE
          value: {{ .Release.Namespace }}
        - name: OS_REGION_NAME
          value: {{ required "Missing region value!" .Values.global.region }}
        - name: OS_USER_DOMAIN_NAME
          value: "tempest"
        - name: OS_PROJECT_DOMAIN_NAME
          value: "tempest"
        - name: OS_INTERFACE
          value: "public"
        - name: OS_ENDPOINT_TYPE
          value: "public"
        - name: OS_PASSWORD
          value: {{ .Values.tempestAdminPassword | quote }}
        - name: OS_IDENTITY_API_VERSION
          value: "3"
        - name: OS_AUTH_URL
          value: "http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{ required "Missing clusterDomain value!" .Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{required "Missing region value!" .Values.global.region}}.{{ required "Missing tld value!" .Values.global.tld}}{{end}}:5000/v3"
      resources:
        requests:
          memory: "1024Mi"
          cpu: "750m"
        limits:
          memory: "4096Mi"
          cpu: "2000m"
      volumeMounts:
        - mountPath: /{{ .Chart.Name }}-etc
          name: {{ .Chart.Name }}-etc
        - mountPath: /container.init
          name: container-init
  volumes:
    - name: {{ .Chart.Name }}-etc
      configMap:
        name: {{ .Chart.Name }}-etc
    - name: container-init
      configMap:
        name: {{ .Chart.Name }}-bin
        defaultMode: 0755
{{ end }}
