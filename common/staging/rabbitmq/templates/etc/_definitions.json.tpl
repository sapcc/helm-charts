{{- $envAll := . -}}
{
    "permissions": [
{{- range $_key, $_user := merge .Values.users }}
{{- $permissions := dict "user" $_user.user "vhost" "/" "read" ".*" "write" ".*" "configure" ".*" }}
{{ toJson $permissions | indent 8 }},
{{- end }}
{{- if .Values.metrics.enabled }}
        {"configure":".*","read":".*","user":"{{.Values.metrics.user}}","vhost":"/","write":".*"},
{{- end }}
        {"configure":".*","read":".*","user":"guest","vhost":"/","write":".*"}
    ],
    "users": [
{{- range $_key, $_user := merge .Values.users }}
{{- $tags := "" }}
{{- $users := dict "name" $_user.user "tags" (tuple $_user.user | include "rabbitmq.tags") "password" (tuple $envAll $_user.user $_user.password | include "rabbitmq.pass") }}
{{ toJson $users | indent 8 }},
{{- end }}
{{- if .Values.metrics.enabled }}
        {"name":"{{.Values.metrics.user}}","password":"{{tuple . .Values.metrics.user .Values.metrics.password | include "rabbitmq.pass"}}","tags":"monitoring"},
{{- end }}
        {"name":"guest","password":"{{ tuple . .Values.users.default.user .Values.users.default.password | include "rabbitmq.pass" }}","tags":"monitoring"}
    ],
    "vhosts": [
        {"name":"/"}
    ]
}