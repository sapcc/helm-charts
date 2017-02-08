#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

# for now this is the same procedure for all agent processes
function process_config_common {
  # copy our template
  mkdir -p /etc/monasca/agent/conf.d
  cp /monasca-etc/agent-agent.yaml /etc/monasca/agent/agent.yaml

  # replace placeholders with actual values
  sed "s|{args.ca_file}|${OS_CACERT}|" -i /etc/monasca/agent/agent.yaml
  sed "s|{hostname}|$KUBE_NODE_NAME|" -i /etc/monasca/agent/agent.yaml
  if [ ! -z $KUBE_CONTAINER_NAME ]; then
    sed "s|{kube_container_name}|$KUBE_CONTAINER_NAME|" -i /etc/monasca/agent/agent.yaml
  else
    sed "/kubernetes.container_name: *{kube_container_name}/d" -i /etc/monasca/agent/agent.yaml
  fi
  sed "s|{kube_pod_name}|$KUBE_POD_NAME|" -i /etc/monasca/agent/agent.yaml
  if [ ! -z $MONASCA_AGENT_SERVICE_DEFAULT ]; then
    sed "s|{service}|$MONASCA_AGENT_SERVICE_DEFAULT|" -i /etc/monasca/agent/agent.yaml
  else
    sed "/service: *{service}/d" -i /etc/monasca/agent/agent.yaml
  fi
  if [ ! -z $MONASCA_AGENT_COMPONENT_DEFAULT ]; then
    sed "s|{component}|$MONASCA_AGENT_COMPONENT_DEFAULT|" -i /etc/monasca/agent/agent.yaml
  else
    sed "/component: *{component}/d" -i /etc/monasca/agent/agent.yaml
  fi
}


function start_application_common {
  # user mon-agent is created in Dockerfile
  mkdir -p /var/log/monasca/agent
}
