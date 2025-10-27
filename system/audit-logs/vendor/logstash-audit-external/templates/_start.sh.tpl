#!/bin/bash

if test -f "/tls-secret/tls.key"; then
   openssl pkcs8 -in /tls-secret/tls.key -topk8 -nocrypt -out /usr/share/logstash/config/tls.key
fi

/usr/share/logstash/bin/logstash -f /audit-etc/logstash.conf --config.reload.automatic --path.settings /audit-etc/
