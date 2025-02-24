{{- define "prometheusVMware.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- /* 
Template around bedrock alerts 
Author: <Christoph Richter christoph.richter@sap.com>
Description: 
              The original alerting rule is then wrapped by a label_replace function.
              The label_replace adds a new label "bedrock" with the value "true" if the alert is relevant for bedrock.
              The label_replace adds a new label "bedrock" with the value "false" if the alert is not relevant for bedrock.
              The mappingKey is dynamically set within values.yaml for each alertname.
*/}}
{{- define "bedrockConfirm.expr" -}}
{{- $expr := index . 0 -}}
{{- $mappingKey := index . 1 -}}
label_replace(
    {{ $expr }} unless on({{ $mappingKey }})
    (
        group by (project, {{ $mappingKey }}) (
            vrops_virtualmachine_system_powered_on{region="eu-de-1", vccluster=~"productionbb\\d+"}
        )
        and on(project)
        group by (project) (
            label_replace(
                limes_project_usage{domain=~"iaas-.*"},
                "project", "$$1", "project_id", "(.*)"
            )
        )
    ),
    "bedrock", "false", "bedrock", "")
or
label_replace(
    {{ $expr }} and on({{ $mappingKey }})
    (
        group by (project, {{ $mappingKey }}) (
            vrops_virtualmachine_system_powered_on{region="eu-de-1", vccluster=~"productionbb\\d+"}
        )
        and on(project)
        group by (project) (
            label_replace(
                limes_project_usage{domain=~"iaas-.*"},
                "project", "$$1", "project_id", "(.*)"
            )
        )
    ),
    "bedrock", "true", "bedrock", ""
)
{{- end -}}
