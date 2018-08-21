{{- define "helm-toolkit.snippets.network_container_agent" -}}
{{- $env := index . 0 -}}
{{- $containerName := index . 1 -}}
image: {{$env.Values.global.imageRegistry}}/{{$env.Values.agent.image_name}}:{{$env.Values.agent.image_tag}}
imagePullPolicy: IfNotPresent
securityContext:
  privileged: true
command: ["/container.init/{{ $containerName }}-start"]
env:
  - name: SENTRY_DSN
    valueFrom:
      secretKeyRef:
        name: sentry
        key: neutron.DSN.python
  - name: DEBUG_CONTAINER
    value: "false"
readinessProbe:
  exec:
    command:
      - cat
      - /var/lib/neutron/{{ $containerName }}-ready
  initialDelaySeconds: 5
  timeoutSeconds: 10
{{- end -}}
