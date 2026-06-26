{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common container spec for inventory-updater
Params:
  root: root context (.)
  name: container name
  args: list of container args
  ports: optional ports section
*/}}
{{- define "inventory-updater.container" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $args := .args -}}
{{- $ports := .ports -}}
- name: {{ $name }}
  image: {{ required ".Values.global.registry missing" $root.Values.global.registry }}/{{ required ".Values.updater.image.name missing" $root.Values.updater.image.name }}:{{ required ".Values.updater.image.tag missing" $root.Values.updater.image.tag }}
  env:
  - name: REDFISH_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ include "fullname" $root }}
        key: redfish_username
  - name: REDFISH_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "fullname" $root }}
        key: redfish_password
  - name: NETBOX_TOKEN
    valueFrom:
      secretKeyRef:
        name: {{ include "fullname" $root }}
        key: netbox_token
  command:
    - /usr/bin/python3
  args:
{{ toYaml $args | indent 4 }}
  volumeMounts:
    - name: updater-config
      mountPath: /{{ include "fullname" $root }}/config
      readOnly: true
  resources:
{{ toYaml $root.Values.resources | indent 4 }}
{{- if $ports }}
  ports:
{{ toYaml $ports | indent 4 }}
{{- end }}
{{- end -}}
