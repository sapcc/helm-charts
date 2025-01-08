{{- define "prometheusVMware.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "bedrockConfirm.expr" -}}
{{- $expr := index . 0 -}}
{{- $mappingKey := index . 1 -}}
expr: >
  label_replace(
      {{ $expr }} unless on({{ $mappingKey }})
      (
          group by (project, {{ $mappingKey }}) (
              vrops_virtualmachine_system_powered_on{region="eu-de-1", vccluster=~"^productionbb\\d+$"}
          )
          and on(project) 
          group by (project) (
              label_replace(
                  limes_project_usage{domain=~"iaas-.*"},
                  "project", "$$1", "project_id", "(.*)"
              )
          )
      ),
      "bedrock", "no", "bedrock", "")
  or
  label_replace(
      {{ $expr }} and on({{ $mappingKey }})
      (
          group by (project, {{ $mappingKey }}) (
              vrops_virtualmachine_system_powered_on{region="eu-de-1", vccluster=~"^productionbb\\d+$"}
          )
          and on(project) 
          group by (project) (
              label_replace(
                  limes_project_usage{domain=~"iaas-.*"},
                  "project", "$$1", "project_id", "(.*)"
              )
          )
      ),
      "bedrock", "yes", "bedrock", ""
  )
{{- end -}}
