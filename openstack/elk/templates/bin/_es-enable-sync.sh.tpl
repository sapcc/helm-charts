#!/bin/bash

unset http_proxy; curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "all"
  }
}
'
