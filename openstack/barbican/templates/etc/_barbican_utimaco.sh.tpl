#!/bin/bash
set -ex

utimaco ()
{
    echo "Setting up Utimaco HSM ..."
    mv /opt/utimaco /utimaco/
    echo "library_path = .."
    mv /etc/utimaco/cs_pkcs11_R3.cfg /utimaco
    chmod -R a+rX /utimaco
}

{{- if .Values.hsm.utimaco_hsm.enabled }}
utimaco
{{- end }}
