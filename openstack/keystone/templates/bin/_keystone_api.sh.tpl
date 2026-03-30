#!/bin/bash

# Copyright 2017 The Openstack-Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

COMMAND="${@:-start}"

function start () {

  for KEYSTONE_WSGI_SCRIPT in keystone-wsgi-public; do
    cp -a $(type -p ${KEYSTONE_WSGI_SCRIPT}) /var/www/cgi-bin/keystone/
  done

  a2dismod status

  {{- if .Values.tls.enabled }}
  a2enmod ssl
  {{- end }}

  if [ -f /etc/apache2/envvars ]; then
     # Loading Apache2 ENV variables
     source /etc/apache2/envvars
  fi

  if [ ! -d "$APACHE_RUN_DIR" ]; then
    # create a apache2 runtime directory
    mkdir "$APACHE_RUN_DIR"
  fi

  if [ -f "$APACHE_PID_FILE" ]; then
    # Remove the stale pid for debian/ubuntu images
    rm -f "$APACHE_PID_FILE"
  fi

  {{- if .Values.federation.saml.enabled }}
  # Generate shibboleth2.xml and federation-saml.conf at runtime from the
  # tenant-list ConfigMap (keystone-saml-tenant-list). This avoids duplicating
  # tenant data in the Keystone chart values — all tenant data lives in the
  # federation repo and is passed through via ConfigMaps.
  mkdir -p /etc/shibboleth/metadata /etc/shibboleth/sp-keys /var/run/shibboleth /var/cache/shibboleth
  python3 /scripts/generate-saml-config.py
  # If shibd is available and we are running out-of-process, start it
  if command -v shibd &> /dev/null; then
    echo "Starting shibd daemon for SAML federation..."
    shibd -t 2>/dev/null && shibd -f || echo "WARN: shibd not started, running mod_shib in-process mode"
  fi
  {{- end }}

  # Start Apache2
  exec apache2 -DFOREGROUND
}

function stop () {
  sleep {{ coalesce .Values.shutdownDelaySeconds .Values.global.shutdownDelaySeconds 10 }}
  apachectl -k graceful-stop
}

$COMMAND
