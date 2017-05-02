{{- /**********************************************************************************/ -}}
{{- define "job_spec" -}}
{{- $repo    := index . 0 -}}
{{- $values  := index . 1 }}
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
        image: {{$values.global.docker_repo}}/swift-http-import:{{$values.image_version}}
        args:
          - /etc/http-import/config/{{$repo}}.yaml
        {{- if $values.debug}}
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

{{- /**********************************************************************************/ -}}
{{- /* Switch to inbuild coalesce until all regions updated to helm v.2.3.0 */ -}}
{{- define "my_coalesce" -}}
{{- $first  := index . 0 -}}
{{- $second := index . 1 -}}
{{- if $first -}}
{{ $first }}
{{- else if $second -}}
{{ $second }}
{{- else -}}
''
{{- end -}}
{{- end -}}
