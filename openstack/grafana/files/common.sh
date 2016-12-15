#!/usr/bin/env bash

function prepare_environment {
    if [ -d "/cluster-config" ]; then
      for config in /cluster-config/* ; do
        env=$(basename $config | tr '[.a-z]' '[_A-Z]')
        export $env="`cat $config`"
      done
    fi

    if [ -d "/cluster-secret" ]; then
      for config in /cluster-secret/* ; do
        env=$(basename $config | tr '[.a-z]' '[_A-Z]')
        export $env="`cat $config`"
      done
    fi

    if [ -n "${CLUSTER_DNS_DOMAIN}" ]; then
      export BARBICAN_DB_HOST=postgres-barbican.${CLUSTER_DNS_DOMAIN}
      export CINDER_DB_HOST=postgres-cinder.${CLUSTER_DNS_DOMAIN}
      export GLANCE_DB_HOST=postgres-glance.${CLUSTER_DNS_DOMAIN}
      export IRONIC_DB_HOST=postgres-ironic.${CLUSTER_DNS_DOMAIN}
      export KEYSTONE_DB_HOST=postgres-keystone.${CLUSTER_DNS_DOMAIN}
      export MANILA_DB_HOST=postgres-manila.${CLUSTER_DNS_DOMAIN}
      export NOVA_DB_HOST=postgres-nova.${CLUSTER_DNS_DOMAIN}
      export DESIGNATE_DB_HOST=designate-mariadb.${CLUSTER_DNS_DOMAIN}
      export NEUTRON_DB_HOST=postgres-neutron.${CLUSTER_DNS_DOMAIN}
      export MONGODB_HOST=mongodb.${CLUSTER_DNS_DOMAIN}
      export RABBITMQ_HOST=rabbitmq.${CLUSTER_DNS_DOMAIN}
      export MEMCACHED_HOST=memcached.${CLUSTER_DNS_DOMAIN}


      #This is for backward compatibility in Monasca scripts and will be removed
      export KEYSTONE_HOST=keystone.${CLUSTER_DNS_DOMAIN}

      export IRONIC_HOST=ironic-api.${CLUSTER_DNS_DOMAIN}
    fi

    if [ -n "${CEILOMETER_DNS_DOMAIN}" ]; then
      export CEILOMETER_HOST=celiometer-api.${CEILOMETER_DNS_DOMAIN}
      export CEILOMETER_MONGODB_HOST=ceilometer-mongodb.${CEILOMETER_DNS_DOMAIN}
      export CEILOMETER_RABBITMQ_HOST=ceilometer-rabbitmq.${CEILOMETER_DNS_DOMAIN}
    fi
}


function start_application {

if [ "$DEBUG_CONTAINER" = "true" ]
then
    tail -f /dev/null
else
    _start_application
fi

}

CLUSTER_SCRIPT_PATH=/openstack-kube/openstack-kube/scripts
CLUSTER_CONFIG_PATH=/openstack-kube/openstack-kube/etc

export MY_IP=$(ip route get 1 | awk '{print $NF;exit}')

prepare_environment

