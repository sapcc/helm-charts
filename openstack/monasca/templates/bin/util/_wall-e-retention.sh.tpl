{{- define "util_wall_e_retention_sh_tpl" -}}
#!/bin/bash

export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}

/usr/local/bin/curator --http_auth {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} --host {{.Values.monasca_elasticsearch_endpoint_host_internal}} --port {{.Values.monasca_elasticsearch_port_internal}} show indices --older-than {{.Values.monasca_elasticsearch_data_retention}} --time-unit days --timestring '%Y-%m-%d' > ${STDOUT_LOC} 2> ${STDERR_LOC}
/usr/local/bin/curator --http_auth {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} --host {{.Values.monasca_elasticsearch_endpoint_host_internal}} --port {{.Values.monasca_elasticsearch_port_internal}} delete indices --older-than {{.Values.monasca_elasticsearch_data_retention}} --time-unit days --timestring '%Y-%m-%d' > ${STDOUT_LOC} 2> ${STDERR_LOC}
/usr/local/bin/curator --http_auth {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} --host {{.Values.monasca_elasticsearch_endpoint_host_internal}} --port {{.Values.monasca_elasticsearch_port_internal}} show indices --older-than {{.Values.monasca_elasticsearch_data_retention}} --time-unit days --timestring '%Y.%m.%d' > ${STDOUT_LOC} 2> ${STDERR_LOC}
/usr/local/bin/curator --http_auth {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} --host {{.Values.monasca_elasticsearch_endpoint_host_internal}} --port {{.Values.monasca_elasticsearch_port_internal}} delete indices --older-than {{.Values.monasca_elasticsearch_data_retention}} --time-unit days --timestring '%Y.%m.%d' > ${STDOUT_LOC} 2> ${STDERR_LOC}
{{ end }}
