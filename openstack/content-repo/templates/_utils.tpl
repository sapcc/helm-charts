When passed via `helm upgrade --set`, the image version is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "image_version" -}}
  {{- if typeIs "string" .image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .image_version -}}
      {{.image_version | printf "%0.f"}}
    {{- else -}}
      {{.image_version}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "job_spec" -}}
{{- $repo        := index . 0 -}}
{{- $values      := index . 1 -}}
{{- $repo_values := index $values.repos $repo }}
spec:
  template:
    spec:
      restartPolicy: OnFailure
      volumes:
        - name: config
          configMap:
            name: swift-http-import
        - name: secret
          secret:
            secretName: swift-http-import
      containers:
      - name: swift-http-import
        image: {{$values.global.docker_repo}}/swift-http-import:{{ include "image_version" $values }}
        args:
          - /etc/http-import/config/{{$repo}}.yaml
        {{- if or $values.debug $repo_values.debug }}
        env:
          - name: 'DEBUG'
            value: '1'
        {{- end}}
        volumeMounts:
          - mountPath: /etc/http-import/config
            name: config
          - mountPath: /etc/http-import/secret
            name: secret
{{- end -}}
