#!/bin/bash
set -ex

utimaco ()
{
    cp -a /opt/utimaco/. /utimaco/
    mv /etc/utimaco/cs_pkcs11_R3*.cfg /utimaco/
    chmod -R a+rX /utimaco
}

{{- if .Values.hsm.utimaco_hsm.enabled }}
utimaco
{{- end }}
