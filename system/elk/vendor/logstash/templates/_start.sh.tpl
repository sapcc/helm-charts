#!/bin/bash

if test -f "/tls-secrets/tls.key"; then
   openssl pkcs8 -in /tls-secrets/tls.key -topk8 -nocrypt -out /usr/share/logstash/config/tls.key
fi

/usr/share/logstash/bin/logstash -f /elk-etc/logstash.conf --config.reload.automatic --path.settings /elk-etc/
