{{- include "nova.helpers.ini_sections.api_database" . }}

{{- include "ini_sections.database" . }}

{{ include "util.helpers.valuesToIni" .Values.conductor.config_file }}
