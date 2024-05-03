#!/bin/bash

#set -x;

/usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh -icl -key /usr/share/opensearch/config/certs/admin/tls.key -cert  /usr/share/opensearch/config/certs/admin/tls.crt -cacert /usr/share/opensearch/config/certs/admin/ca.crt -cd /usr/share/opensearch/config/opensearch-security/ -h opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}
