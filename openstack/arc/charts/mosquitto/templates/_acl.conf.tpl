{{- define "acl.conf" -}}
user O=arc-api,OU=arc-api
topic #
pattern write registration/%o/%u/%c
pattern write reply/+
pattern read identity/%c
{{ end }}
