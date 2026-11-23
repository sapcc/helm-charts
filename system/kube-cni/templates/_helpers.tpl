{{/* Keep image pins intact; use only the readable tag for version selection. */}}
{{- define "kube-cni.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}
