#!/bin/bash

#set -x;

#mkdir /usr/share/opensearch/config/security
#cp /usr/share/opensearch/config/opensearch-security/*.yml /usr/share/opensearch/config/security/

#export PWS=`cat /usr/share/opensearch/config/security/internal_users.yml |grep "hash:"| awk -F: '{ print $2}'|tr -d "^ "|tr -d \"`

#for i in $PWS; do
#  PW=`/usr/share/opensearch/plugins/opensearch-security/tools/hash.sh -p "$i" | tail -1`
#  sed -i -e 's|'"$i"'|'"$PW"'|' /usr/share/opensearch/config/security/internal_users.yml
#done

/usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh -icl -key /usr/share/opensearch/config/certs/admin/tls.key -cert  /usr/share/opensearch/config/certs/admin/tls.crt -cacert /usr/share/opensearch/config/certs/admin/ca.crt -cd /usr/share/opensearch/config/opensearch-security/ -h opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}
