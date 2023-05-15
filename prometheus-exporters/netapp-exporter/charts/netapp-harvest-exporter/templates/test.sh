#!/bin/bash
#
#
# fetch all prommetheus metrics with name netapp_poller_status using curl
metrics=curl -s -H "Accept: application/json" -H "Content-Type: application/json" http://localhost:9090/api/v1/query?query=netapp_poller_status | jq -r '.data.result[] | .metric.node + " " + .metric.cluster + " " + .metric.poller + " " + .value[1]' | sort -k 2,2 -k 1,1
