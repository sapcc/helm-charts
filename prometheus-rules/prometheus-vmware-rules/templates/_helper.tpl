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
              The mappingKey is dynamically set within values.yaml for each alertname.
*/}}
{{- define "bedrockConfirm.expr" -}}
{{- $expr := index . 0 -}}
{{- $mappingKey := index . 1 -}}
({{ $expr }}) + on({{ $mappingKey }}) group_left(bedrock) label_replace(vrops_hostsystem_hostgroups, "bedrock", "true", "hostgroups", ".*iaas.*") * 0
{{- end -}}