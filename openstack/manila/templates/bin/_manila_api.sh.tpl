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

  if type -p manila-wsgi > /dev/null; then
    cp -a $(type -p manila-wsgi) /var/www/cgi-bin/manila/manila-wsgi
  else
    cat > /var/www/cgi-bin/manila/manila-wsgi <<'WSGI'
import threading
_app = None
_lock = threading.Lock()
with _lock:
    if _app is None:
        from oslo_config import cfg
        cfg.CONF.reset()
        from manila.wsgi.wsgi import initialize_application
        _app = initialize_application()
application = _app
WSGI
    chmod 755 /var/www/cgi-bin/manila/manila-wsgi
  fi

  a2dismod status

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
  sleep {{ coalesce .Values.shutdownDelaySeconds .Values.global.shutdownDelaySeconds 10 }}
  apachectl -k graceful-stop
}

$COMMAND
