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

{{ define "utils.kubernetes_pod_az_affinity" -}}
{{- $envAll := index . 0 -}}
{{- $availability_zone := index . 1 -}}
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
            - key: "{{ $envAll.Values.global.topology_key | default "topology.kubernetes.io/zone" }}"
              operator: In
              values:
                - {{ $availability_zone }}
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

{{ define "kubernetes_pod_AZ_spread" -}}
{{- $envAll := index . 0 -}}
{{- $application := index . 1 -}}
{{- $component := index . 2 -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: "app"
              operator: In
              values:
                - {{$envAll.Release.Name}}
            - key: "component"
              operator: In
              values:
                - {{$component}}
        topologyKey: "topology.kubernetes.io/zone"
    - weight: 2
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: "app"
              operator: In
              values:
                - {{$envAll.Release.Name}}
            - key: "component"
              operator: In
              values:
                - {{$component}}
        topologyKey: "kubernetes.io/hostname"
{{- end }}

