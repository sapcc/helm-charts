{{- define "ironic_conductor_configmap" }}
  {{- $conductor := index . 1 }}
  {{- with index . 0 }}
apiVersion: v1
kind: ConfigMap
metadata:
{{- if $conductor.name }}
  name: ironic-conductor-{{$conductor.name}}-etc
{{- else }}
  name: ironic-conductor-etc
{{- end }}
  labels:
    system: openstack
    type: configuration
    component: ironic
  options:
    jinja2_options:
      variable_start_string: '{='
      variable_end_string: '=}'
data:
  ironic-conductor.conf: |
{{ list . $conductor | include "ironic_conductor_conf" | indent 4 }}
---
apiVersion: v1
kind: Secret
metadata:
{{- if $conductor.name }}
  name: ironic-conductor-{{$conductor.name}}-etc-secret
{{- else }}
  name: ironic-conductor-etc-secret
{{- end }}
  labels:
    system: openstack
    type: configuration
    component: ironic
data:
  ipxe_config.template: |
    {{- if $conductor.jinja2 }}
    {% raw -%}
    {{- end }}
{{ list . $conductor | include "ipxe_config_template" | b64enc | indent 4 }}
    {{- if $conductor.jinja2 }}
    {%- endraw %}
    {{- end }}
  {{- end }}
{{- end }}
