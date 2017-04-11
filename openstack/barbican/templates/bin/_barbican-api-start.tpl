#!/usr/bin/env bash

set -e

function process_config {
    cp /barbican-etc/barbican.conf /etc/barbican/barbican.conf
    cp /barbican-etc/barbican-api-paste.ini /etc/barbican/barbican-api-paste.ini
    cp /barbican-etc/policy.json /etc/barbican/policy.json
}



process_config
exec /barbican/bin/barbican-api
