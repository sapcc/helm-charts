#!/bin/bash
curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" ${CLUSTER_HOST}/
if [ $? -ne 0 ]; then
  echo "First user failed, trying second user"
  # Second attempt with user2 if user1 fails
  curl -s -u "${ADMIN2_USER}:${ADMIN2_PASSWORD}" ${CLUSTER_HOST}/
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  else
    export BASIC_AUTH_HEADER=${ADMIN2_USER}:${ADMIN2_PASSWORD}
  fi
else
  export BASIC_AUTH_HEADER=${ADMIN_USER}:${ADMIN_PASSWORD}
fi

# Get all indices, except system and datastream indices (start with a dot)
for i in $(curl -s -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_cat/indices?v"|awk '{ print $3 }'|grep -v "^\."|sort|sed 's/-[0-9].*\.[0-9].*\.[0-9].*$//'|uniq|grep -v index|grep -v "alerts-other"|grep -v deployments|grep -v maillog|grep -v ss4o|grep -v sample |grep -v awx | grep -v alias| grep -v top_queries)
  do
    # Delete all dashboard pattern to update all fields, reload if dashboard patterns is not supported via api
    curl -s --fail -XDELETE -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}*"
    curl -s -XPOST --header "content-type: application/JSON" -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}*" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}*\", \"timeFieldName\": \"@timestamp\" } }"
done

# Creating Dashboards index pattern for all available datastreams
for i in $(curl -s -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_data_stream/*?pretty=true"|grep name|grep -v "index_name"|grep -v "@timestamp"|awk -F: '{ print $2}'|awk -F\" '{ print $2 }'|sed 's/...........$//')
  do
    echo "using datastream $i from Opensearch-Logs"
    echo "setting OpenSearch dashboard index mapping for index $i"
    curl -s --fail -XGET -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}*"
    if [ $? -eq 0 ]
    then
        echo "index ${i} already exists in Opensearch dashboard"
    else
      echo "INFO: creating index-pattern in Dashboards for datastream $i"
      curl -s -XPOST --header "content-type: application/JSON" -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}*" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}*\", \"timeFieldName\": \"@timestamp\" } }"
    fi
done
