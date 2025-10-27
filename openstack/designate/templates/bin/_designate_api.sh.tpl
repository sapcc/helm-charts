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

  for DESIGNATE_WSGI_SCRIPT in designate-api-wsgi; do
    cp -a $(type -p ${DESIGNATE_WSGI_SCRIPT}) /var/www/cgi-bin/designate/
  done

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

  # Start Apache2
  exec apache2 -DFOREGROUND
}

function stop () {
  apachectl -k graceful-stop
}

#
# all designate configs
#
function process_config {
    cp /designate-etc/* /etc/designate/

    echo "[DEFAULT]" > /etc/designate/hostname.conf
    echo "host = $NODE_NAME" >> /etc/designate/hostname.conf
}

process_config

$COMMAND
