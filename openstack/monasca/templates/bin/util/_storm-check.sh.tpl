{{- define "util_storm_check_sh_tpl" -}}
#!/bin/bash
#set -x


# check script for thresh cluster in storm
sleep 30

export PYTHON=/usr/bin/python2.7
export THRESH_CLUSTER=$(/opt/storm/current/bin/storm list)
echo $THRESH_CLUSTER|grep -q "thresh-cluster"
export RESULT=$?
echo $RESULT
if [ "$RESULT" -eq 0 ]; then
   echo "deleting old thresh-cluster"
   /opt/storm/current/bin/storm kill thresh-cluster
   
   until /opt/storm/current/bin/storm list| grep -q "No topologies running"
   do sleep 5
   done
   echo "uploading new thresh-cluster"
   /opt/storm/current/bin/storm jar /opt/monasca/monasca-thresh.jar monasca.thresh.ThresholdingEngine /etc/monasca/thresh-config.yml thresh-cluster
elif [[ "$THRESH_CLUSTER" =~ "No topologies running" ]]; then
  echo "no thresh-cluster found, uploading new thresh-cluster"
   /opt/storm/current/bin/storm jar /opt/monasca/monasca-thresh.jar monasca.thresh.ThresholdingEngine /etc/monasca/thresh-config.yml thresh-cluster 
else
  echo "storm not working, please check"
  ps -efa
fi

{{ end }}
