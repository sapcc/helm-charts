{{ define "kubernetes_pod_anti_affinity" -}}
{{- $envAll := index . 0 -}}
{{- $application := index . 1 -}}
{{- $component := index . 2 -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 10
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchExpressions:
          - key: release_name
            operator: In
            values:
            - {{$envAll.Release.Name}}
          - key: application
            operator: In
            values:
            - {{$application}}
          - key: component
            operator: In
            values:
            - {{$component}}
{{- end }}

{{ define "kubernetes_pod_az_affinity" -}}
{{- $availability_zone := index . 0 -}}
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
            - key: "topology.kubernetes.io/zone"
              operator: In
              values:
                - {{$availability_zone}}
{{- end }}

{{- define "kubernetes_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
                - key: cloud.sap/maintenance-state
                  operator: In
                  values:
                  - operational
{{- end }}
