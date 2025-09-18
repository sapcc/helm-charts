#!/bin/bash
set -ex

utimaco ()
{
    mkdir -p /utimaco
    cp -a /opt/utimaco/. /utimaco/
    chmod -R a+rX /utimaco
}

{{- if .Values.hsm.utimaco_hsm.enabled }}
utimaco
{{- end }}
