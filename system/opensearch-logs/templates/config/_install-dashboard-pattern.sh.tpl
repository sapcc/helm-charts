#!/bin/bash

# 0. Check for index policy
for i in $(curl -s -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${CLUSTER_HOST}/_cat/indices?v"|awk '{ print $3 }'|awk -F- '{ print $1 }'|sort|uniq|grep -v "\."|grep -v "index")
  do
    echo "using index $i from Opensearch-Logs"
    echo "setting OpenSearch dashboard index mapping for index $i"
    curl --header "content-type: application/JSON" --fail -XGET -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}-*"
    if [ $? -eq 0 ]; then
       echo "index ${i} already exists in Opensearch dashboard"
    else
      echo "INFO: creating index-pattern in Dashboards for $i logs"
      curl -XPOST --header "content-type: application/JSON" -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}-*" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}-*\", \"timeFieldName\": \"@timestamp\" } }"
    fi
done

# Dashboard index pattern for all available datastreams
for i in $(curl -s -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${CLUSTER_HOST}/_cat/aliases?v"|grep "\-ds"|awk '{ print $1 }'|uniq)
  do
    echo "using datastream $i from Opensearch-Logs"
    echo "setting OpenSearch dashboard index mapping for index $i"
    curl --header "content-type: application/JSON" --fail -XGET -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}"
    if [ $? -eq 0 ]; then
        echo "index ${i} already exists in Opensearch dashboard"
    else
      echo "INFO: creating index-pattern in Dashboards for datastream alias $i"
      curl -XPOST --header "content-type: application/JSON" -u ${ADMIN_USER}:${ADMIN_PASSWORD} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}\", \"timeFieldName\": \"@timestamp\" } }"
    fi
done
