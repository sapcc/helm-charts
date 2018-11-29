{{- define "ironic_conductor_configmap" }}
  {{- $conductor := index . 1 }}
  {{- with index . 0 }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: ironic-conductor-{{$conductor.name}}-etc
  labels:
    system: openstack
    type: configuration
    component: ironic
data:
  ironic-conductor.conf: |
{{ list . $conductor | include "ironic_conductor_conf" | indent 4 }}
  pxe_config.template: |
    {{- if $conductor.jinja2 }}
    {% raw -%}
    {{- end }}
{{ list . $conductor | include "pxe_config_template" | indent 4 }}
    {{- if $conductor.jinja2 }}
    {%- endraw %}
    {{- end }}
  ipxe_config.template: |
    {{- if $conductor.jinja2 }}
    {% raw -%}
    {{- end }}
{{ list . $conductor | include "ipxe_config_template" | indent 4 }}
    {{- if $conductor.jinja2 }}
    {%- endraw %}
    {{- end }}
  {{- end }}
{{- end }}
