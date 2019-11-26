{{ define "utils.snippets.debug.debuggable_port" }}
    {{- $override := index . 0 }}
    {{- if $override }}dbg{{ end }}
{{- end }}

{{ define "utils.snippets.debug.debug_port_container" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- with $envAll }}
        {{- if $override }}
- name: reverse-proxy
  image: {{ default "hub.global.cloud.sap" .Values.global.imageRegistry }}/{{ .Values.global.fernetRouter.image }}
  imagePullPolicy: {{- if hasSuffix "latest" .Values.global.fernetRouter.image }} Always {{- else }} IfNotPresent {{- end }}
  ports:
  - name: {{ $portName }}
    containerPort: 80
  volumeMounts:
  - mountPath: /etc/fernet-router
    name: {{ $portName }}-fernet-router
    readOnly: true
  - mountPath: /fernet-keys
    name: fernet
    readOnly: true
        {{- end }}
    {{- end }}
{{- end }}

{{ define "utils.snippets.debug.debug_port_volumes" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- with $envAll }}
        {{- if $override }}
- name: {{ $portName }}-fernet-router
  configMap:
    name: {{ $portName }}-fernet-router
    defaultMode: 0444
- name: fernet
  secret:
    secretName: keystone-fernet
    defaultMode: 0444
        {{- end }}
    {{- end }}
{{- end }}


{{ define "utils.snippets.debug.debug_port_configmap" }}
    {{- $envAll := index . 0 }}
    {{- $override := index . 1 }}
    {{- $portName := index . 2 }}
    {{- $port := index . 3 }}
    {{- with $envAll }}
        {{- if $override }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $portName }}-fernet-router
  labels:
    system: openstack
    type: config
    component: fernet-router
data:
  local_init.lua: |
    -- memcache for token lookup
    local memcached = require "resty.memcached"

    user_overrides = { {{ range $k, $v := $override }}["{{$k}}"] = "{{$v}}",{{ end }} }
    function get_user_from_memcached(user)
      local memc = memcached:new()
      memc:set_timeout(250)
      memc:connect("{{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}", {{ .Values.memcached.memcached.port | default 11211 }})
      local data = memc:get("nginx-token-redirect-" .. user)
      memc:set_keepalive(10000, 100)

      return data
    end

    function user_override(user)
      if not user then
        return
      end

      return user_overrides[user] or get_user_from_memcached(user)
    end
    function project_override(project) return user_overrides[project] end
    function default_upstream() return 'http://127.0.0.1:{{$port}}' end
        {{ end }}
    {{- end }}
{{- end }}

{{ define "utils.snippets.debug.debug_port_volumes_and_configmap" }}
    {{- $override := index . 1 }}
    {{- if $override }}
{{- include "utils.snippets.debug.debug_port_volumes" . | indent 6 }}
---
{{- include "utils.snippets.debug.debug_port_configmap" . }}
    {{- end }}
{{- end }}


{{ define "utils.snippets.debug.eventlet_backdoor_ini" }}
backdoor_socket=/var/lib/{{.}}/eventlet_backdoor-{pid}.socket
{{ end }}
