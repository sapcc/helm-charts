#!/usr/bin/env python

import click
import socket
import sys

from kubernetes import client, config

@click.command()
@click.option('--namespace', default='monsoon3')
@click.option('--region')
@click.option('--suffix', default='cloud.sap')
def check_node_region(namespace, region, suffix):
    config.load_incluster_config()
    node_name = client.CoreV1Api().read_namespaced_pod(socket.gethostname(), namespace).spec.node_name
    if not node_name.endswith(region + '.' + suffix):
        msg = ("Region value '%(region)s' does not match node '%(node)s'." % {
            'node': node_name, 'region': region})
        sys.exit(msg)
    else:
        click.echo('ok')

if __name__ == '__main__':
    check_node_region()
