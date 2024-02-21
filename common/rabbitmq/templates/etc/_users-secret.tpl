{{- $i := 0 }}
{{- range $user := .Values.users }}
USERNAME_{{ printf "%02d" $i }}: {{"{{"}} resolve "vault+kvv2:///{{ $user.username }}" {{"}}"}}
PASSWORD_{{ printf "%02d" $i }}: {{"{{"}} resolve "vault+kvv2:///{{ $user.password }}" {{"}}"}} 
  {{- if $user.tag }}
TAG_{{ printf "%02d" $i }}: {{ $user.tag }}
  {{- end }}
  {{- $i = (add1 $i) }}
{{- end }}
