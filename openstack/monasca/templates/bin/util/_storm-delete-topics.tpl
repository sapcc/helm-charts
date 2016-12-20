{{- define "util_storm_delete_topics_tpl" -}}
. /container.init/common-start
echo "DELETE ALL KAFKA TOPICS"
echo "------------------------------------------------------------------------------"
echo "Press Ctrl-C to stop within 10 secs"
sleep 10
TOPICS="metrics events raw-events transformed-events stream-definitions transform-definitions alarm-state-transitions alarm-notifications retry-notifications stream-notifications 60-seconds-notifications healthcheck log transformed-log"
for topic in $TOPICS; do
  /opt/kafka/current/bin/kafka-topics.sh --delete --topic $topic --zookeeper ${MONASCA_ZOOKEEPER_ENDPOINTS_URI_LIST} 
done
echo "done"
{{ end }}
