#!/bin/bash
export BASIC_AUTH_HEADER=${ADMIN_USER}:${ADMIN_PASSWORD}

#  Creating aliases for all indexes, because logstash-* is also selecting datastreams besides the logstash-2024... indexes.
for i in $(curl -s -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_cat/indices?v"|awk '{ print $3 }'|grep -v "^\."|sort|sed 's/-[0-9].*\.[0-9].*\.[0-9].*$//'|uniq|grep -v index|grep -v "alerts-other"|grep -v deployments|grep -v maillog|grep -v ss4o|grep -v sample)
  do
    #Creating an alias for all standard indexes, which are not datastreams to mitigate the issue with indexes, where for example storage-* is selecting the index and also the datastream, which shows up in dashboards as duplicate entries
    echo "using index $i from Opensearch-Logs"
    export ALIAS_EXISTS=`curl -s -i -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_cat/aliases/${i}"|grep "content-length"|awk -F: '{ print $2 }'|tr -d '[:space:]'`
    echo "Creating for updating alias $i, because alias setting is only valid for indexes, which were created before the alias creation timestamp"
    curl -s -XPOST --header "content-type: application/JSON" -u  ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_aliases" -H "osd-xsrf: true" -d "{ \"actions\": [ { \"add\": { \"index\": \"${i}-2*\", \"alias\": \"${i}\" } } ] }"
    echo "Deleting old index pattern based on index-* format"
    export DASHBOARD_PATTERN=`curl -s --header "content-type: application/JSON" --fail -XGET -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}-*"|grep "content-length"|awk -F: '{ print $2 }'|tr -d '[:space:]'`
    if [[ "$DASHBOARD_PATTERN" -gt 0 ]]
    then
      echo "Old dashboard pattern exists for for index ${i}, it will be removed"
      curl -s -XDELETE -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}-*"
    else
     echo "No old dashboard pattern for index $i"
    fi
done

# Dashboard index pattern for all available aliases, which are not datastreams
for i in $(curl -s -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_cat/aliases?v"|grep -v "\-ds"|grep -v "^\."|awk '{ print $1 }'|sort|uniq)
  do
    echo "using alias $i from Opensearch-Logs"
    echo "Setting OpenSearch dashboard index mapping for alias $i"
    curl -s --fail -XGET -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}"
    if [ $? -eq 0 ]
    then
      echo "index pattern for alias ${i} already exists in Opensearch dashboard, nothing to do"
    else
      echo "INFO: creating index-pattern in Dashboards for datastream alias $i"
      curl -s -XPOST --header "content-type: application/JSON" -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}\", \"timeFieldName\": \"@timestamp\" } }"
    fi
done


# Dashboard index pattern for all available datastreams
for i in $(curl -s -u ${BASIC_AUTH_HEADER} "${CLUSTER_HOST}/_cat/aliases?v"|grep "\-ds"|awk '{ print $1 }'|sort|uniq)
  do
    echo "using datastream $i from Opensearch-Logs"
    echo "setting OpenSearch dashboard index mapping for index $i"
    curl -s --fail -XGET -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}"
    if [ $? -eq 0 ]
    then
        echo "index ${i} already exists in Opensearch dashboard"
    else
      echo "INFO: creating index-pattern in Dashboards for datastream alias $i"
      curl -s -XPOST --header "content-type: application/JSON" -u ${BASIC_AUTH_HEADER} "${DASHBOARD_HOST}/api/saved_objects/index-pattern/${i}" -H "osd-xsrf: true" -d "{ \"attributes\": { \"title\": \"${i}\", \"timeFieldName\": \"@timestamp\" } }"
    fi
done
