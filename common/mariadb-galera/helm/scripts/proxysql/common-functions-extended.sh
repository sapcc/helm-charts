MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}

{{- if $.Values.proxy.restapi.enabled }}
export PROXYSQL_RESTAPI_ENABLED="true"
  {{- range $servicesKey, $servicesValue := $.Values.services.proxy }}
    {{- if eq $servicesValue.name "backend"}}
      {{- range $portsKey, $portsValue := $servicesValue.ports }}
        {{- if eq $portsValue.name "restapi"}}
export PROXYSQL_RESTAPI_PORT="{{ $portsValue.targetPort }}"
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $.Values.proxy.adminui.enabled }}
export PROXYSQL_WEB_ENABLED="true"
  {{- if $.Values.proxy.adminui.verbosity }}
export PROXYSQL_WEB_VERBOSITY="{{ ($.Values.proxy.adminui.verbosity | int) }}"
  {{- end }}
  {{- range $servicesKey, $servicesValue := $.Values.services.proxy }}
    {{- if eq $servicesValue.name "backend"}}
      {{- range $portsKey, $portsValue := $servicesValue.ports }}
        {{- if eq $portsValue.name "adminui"}}
export PROXYSQL_WEB_PORT="{{ $portsValue.targetPort }}"
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
