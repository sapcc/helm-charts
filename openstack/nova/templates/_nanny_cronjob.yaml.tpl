{{- define "nova.nanny_cronjob" }}
{{- $name := index . 1 }}
{{- with index . 0 }}
{{/* NOTE: We use "mergeOverwrite" instead of "merge" because "merge" overwrites "false" values of the preceding
dictionary with values of the fallback dictionary. We use an empty dictionary as a first argument to prevent inplace
changes on the passed dictionaries */}}
{{- $values := mergeOverwrite (dict) .Values.nanny.default (get .Values.nanny (replace "-" "_" $name)) }}
{{- if $values.enabled }}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nova-nanny-{{ $name }}
  labels:
    system: openstack
    component: nova
    type: nanny
spec:
  schedule: {{ $values.schedule | quote }}
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        metadata:
          {{- tuple . (print "nanny-" $name) "nanny" | include "job_metadata" | indent 10 }}
        spec:
          restartPolicy: OnFailure
          volumes:
          - name: container-init
            configMap:
              name: nova-bin
              defaultMode: 0755
              items:
              - key: nanny-{{ $name }}
                path: nanny-script
          {{- include "utils.trust_bundle.volumes" . | indent 10 }}
          - name: nova-etc
            projected:
              sources:
              - configMap:
                  name: nova-etc
                  items:
                  - key:  nova.conf
                    path: nova.conf
                  - key:  logging.ini
                    path: logging.ini
              - secret:
                  name: nova-etc
                  items:
                  - key: api-db.conf
                    path: nova.conf.d/api-db.conf
                  {{- if $values.add_cell1_conf }}
                  - key: cell1.conf
                    path: nova.conf.d/cell1.conf
                  {{- end }}
          initContainers:
          {{- tuple . (dict "service" (include "nova.helpers.database_services" .)) | include "utils.snippets.kubernetes_entrypoint_init_container" | indent 10 }}
          containers:
          - name: nanny
            image: {{ tuple . "nanny" | include "container_image_nova" }}
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - |
              /container.init/nanny-script
              exit_code=$?
              {{- include "utils.script.job_finished_hook" . | nindent 14 }}
              exit $exit_code
            env:
            {{- if .Values.sentry.enabled }}
            {{- include "utils.sentry_config" . | nindent 12 }}
            {{- end }}
            - name: PYTHONWARNINGS
              value: {{ .Values.python_warnings | quote }}
            volumeMounts:
            - mountPath: /etc/nova
              name: nova-etc
            - mountPath: /container.init
              name: container-init
            {{- include "utils.trust_bundle.volume_mount" . | indent 12 }}
            resources:
              {{- $values.resources | toYaml | nindent 14 }}
{{- end }}
{{- end }}
{{- end }}
