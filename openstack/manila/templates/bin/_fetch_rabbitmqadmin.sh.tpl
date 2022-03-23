#!/bin/sh

set -e

wget http://manila-rabbitmq:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
mv rabbitmqadmin /shared
