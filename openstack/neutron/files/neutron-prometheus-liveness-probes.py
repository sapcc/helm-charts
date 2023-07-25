#! /usr/bin/env python3

import argparse
import os
import requests
import time

parser = argparse.ArgumentParser(prog='neutron-prometheus-liveness-probes',
                                 description="neutron live- and readyness probes against prometheus")
parser.add_argument('--mode', choices=['network', 'bridge', 'agent-state-report'], required=True,
                    help='Entity for which the probes are done')
parser.add_argument('--prometheus-url', default="http://prometheus-openstack.prometheus-openstack:9090",
                    help='Prometheus URL')
parser.add_argument('--last-agent-state-report-secs', default=120, type=int,
                    help='If the last agent-state-report is older than this value, the probe will fail. '
                    'Bear in mind that this should be greater than the agent state report interval. '
                    'Only needed for mode agent-state-report')
parser.add_argument('--fail-on-promethes-connection-error', action='store_true',
                    help='If this switch is set, the script will terminate with exitcode 1 if '
                    'prometheus is not reachable. This means that kubernetes marks the pod not '
                    'ready or restarts it, depending if the probe is a liveness or readyness probe.')
args = parser.parse_args()


QUERY_MAP = {
    'bridge': """
        sum(openstack_subnets_with_dhcp_ip_allocation{network_host="%s"}) by (bridge, network_host)
            unless on(bridge, network_host)
        label_replace(
            neutron_agent_checks_linux_bridge_present, "network_host", "$1", "hostname", "(.*)")""" % os.uname()[1],

    'network': """
        openstack_subnets_with_dhcp_ip_allocation{network_host="%s"}
            unless on(network_id, network_host)
        label_replace(
            label_replace(
                neutron_agent_checks_netns_present, "network_host", "$1", "hostname", "(.*)"),
            "network_id", "$1", "netns", "(.*)")""" % os.uname()[1],
    # using a range query here, as that will return us an array of values,
    # each with a timestamp when this value was collected
    'agent-state-report': """
        min(openstack_neutron_monitor_agents_heartbeat_seconds{neutron_host="%s"})
        by (neutron_host)[%ds:]""" % (os.uname()[1], args.last_agent_state_report_secs)
}

try:
    response = requests.get(args.prometheus_url + "/api/v1/query", params={"query": QUERY_MAP[args.mode]})
except requests.exceptions.ConnectionError as e:
    print(f"Prometheus connection error: {e}")
    exit(1 if args.fail_on_promethes_connection_error else 0)

if response.status_code != 200:
    print(f"Error while running prometheus query: {response.text}")
    exit(2)
data = response.json().get("data", {}).get("result", [])

if args.mode in ("network", "bridge"):
    if len(data) != 0:
        nets = [x["metric"]["network_id" if args.mode == "network" else "bridge"] for x in data]
        print(f"{len(data)} unsynced {'network namespaces' if args.mode == 'network' else 'bridges' }: {nets}")
        exit(3)
    else:
        print(f'All {"network namespaces" if args.mode == "network" else "bridges" } are synced')

if args.mode == "agent-state-report":
    if len(data) == 0:
        print(f'No agent state report found for {os.uname()[1]}. '
              'Either the agent is not running or the prometheus exporter is not working')
        exit(3)
    else:
        # can never be more than one result, because we are querying for a specific host and grouping by that attribute
        # last value in values is the most current one
        time_collected, db_timestamp_age = (int(x) for x in data[0]['values'][-1])
        # right now the database query returns timestamp - now(), which is then the duration imported into prometheus
        # that is supoptimal, because the real age of the last agent state report is obfuscated
        # we should change the query at some point to export unix timestamp instead of duration, one change at a time
        last_report_ago_secs = (time.time() - time_collected) + db_timestamp_age
        if last_report_ago_secs > args.last_agent_state_report_secs:
            print(f'Agent state report is {last_report_ago_secs} seconds old, which is more than the allowed '
                  f'{args.last_agent_state_report_secs} seconds')
            exit(3)
        else:
            print(f'Last agent state that made it to prometheus is {last_report_ago_secs}')
