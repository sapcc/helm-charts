{{/*
   With Helm3, we don't force the replacements of job specs anymore, which
   causes deployment issues since kuberentes job specs are immutable by default.
   We solve this by generating an image specific name for every configmap change,
   therefore no job will be replaced. Instead, a new job will be spawned while
   the old one will be deleted.
*/}}
{{- define "reload_bird_config" -}}
{{- $files := index . 0 -}}
{{- $values := index . 1 | required "values cannot be empty" }}
{{- $config_name := index . 2 | required "config_name cannot be empty" }}
{{- $deployment_name := index . 3 | required "deployment_name cannot be empty" }}
{{- $service_number := index . 4 }}
{{- $domain_number := index . 5 }}
{{- $instance_number := index . 6 }}

{{ $configmap_hash := tuple $files $values.bird_config_path $config_name | include "configmap_bird" | sha256sum}}
---
apiVersion: batch/v1
kind: Job
metadata:
    name: reload-bird-config-{{ $deployment_name }}-{{ $configmap_hash }}
    namespace: px
    labels:
        app: {{ $deployment_name | quote }}
        pxservice: '{{ $service_number }}'
        pxdomain: '{{ $domain_number }}'
        pxinstance: '{{ $instance_number }}'
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: reload-bird-config
          image: keppel.{{ required "A registry mus be set" $values.registry }}.cloud.sap/{{ required "A bird_image must be set" $values.bird_image }}
          imagePullPolicy: IfNotPresent
          command: ["bird-command", "--refresh"]
          volumeMounts:
            - name: bird-socket
              mountPath: /var/run/bird
      volumes:
        - name: bird-socket
          persistentVolumeClaim:
            claimName: {{ $deployment_name }}
{{- end -}}
