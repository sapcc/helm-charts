{{- define "recommender.image" -}}
{{- required ".Values.image.registry missing" .Values.image.registry -}}/{{- required ".Values.recommender.image.repository missing" .Values.recommender.image.repository -}}:{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{- define "admission.image" -}}
{{- required ".Values.image.registry missing" .Values.image.registry -}}/{{- required ".Values.admission.image.repository missing" .Values.admission.image.repository -}}:{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{- define "updater.image" -}}
{{- required ".Values.image.registry missing" .Values.image.registry -}}/{{- required ".Values.updater.image.repository missing" .Values.updater.image.repository -}}:{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
{{- end -}}
