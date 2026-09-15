#!/usr/bin/env python

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Health probe script for OpenStack service that uses RPC/unix domain socket for
communication. Check's the RPC tcp socket status on the process and send
message to service through rpc call method and expects a reply.
Uses oslo's ping method that is designed just for such simple purpose.

For API service script:
  a. checks if the RabbitMQ and DB are reachable over TCP.
These two checks succeed or timeout within 5 seconds.

For other RPC services script:
  a. checks if there are any TCP ESTABLISHED connections to RabbitMQ and DB.
  b. checks if the service can consume message from the queue.

With this (b) RPC check script returns failure to Kubernetes only when
  a. TCP sockets for the RPC communication are not established.
  b. service is not reachable or
  c. service times out sending a reply.

sys.stderr.write() writes to pod's events on failures.

Usage example for Designate Central:
# python health-probe.py --config-file /etc/designate/secrets.conf \
#  --config-file /etc/designate/hostname.conf \
#  --service-name central \
#  --liveness-probe

"""

import json
import os
import psutil
import signal
import socket
import sys
from typing import Optional, Set, Tuple

from sqlalchemy.engine.url import make_url

from oslo_config import cfg
from oslo_context import context
from oslo_log import log
import oslo_messaging

rpc_timeout = int(os.getenv("RPC_PROBE_TIMEOUT", "30"))
rpc_retries = int(os.getenv("RPC_PROBE_RETRIES", "1"))

tcp_probe_timeout = float(os.getenv("TCP_PROBE_TIMEOUT", "5"))
tcp_established = "ESTABLISHED"


def check_service_status(transport: oslo_messaging.Transport) -> None:
    """Verify service status. Return success if service consumes message"""
    try:
        service_queue_name = cfg.CONF.service_name
        service_hostname = cfg.CONF.host or socket.gethostname()
        target = oslo_messaging.Target(
            topic=service_queue_name,
            server=service_hostname,
        )
        if hasattr(oslo_messaging, "get_rpc_client"):
            client = oslo_messaging.get_rpc_client(transport, target, timeout=rpc_timeout, retry=rpc_retries)
        else:
            client = oslo_messaging.RPCClient(transport, target, timeout=rpc_timeout, retry=rpc_retries)
        client.call(context.RequestContext(), "oslo_rpc_server_ping", arg=None)
    except oslo_messaging.exceptions.MessageDeliveryFailure:
        # Log to pod events
        sys.stderr.write("Health probe unable to reach message bus")
        sys.exit(0)  # return success
    except oslo_messaging.rpc.client.RemoteError as re:
        message = getattr(re, "message", str(re))
        if ("Endpoint does not support RPC method" in message) or ("Endpoint does not support RPC version" in message):
            sys.exit(0)  # Call reached the service
        else:
            sys.stderr.write("Health probe unable to reach service")
            sys.exit(1)  # return failure
    except oslo_messaging.exceptions.MessagingTimeout:
        sys.stderr.write("Health probe timed out. Agent is down or response timed out")
        sys.exit(1)  # return failure
    except Exception as ex:
        message = getattr(ex, "message", str(ex))
        sys.stderr.write("Health probe caught exception sending message to service: %s" % message)
        sys.exit(0)
    except:
        sys.stderr.write("Health probe caught exception sending message to service")
        sys.exit(0)
    finally:
        if client.transport:
            client.transport.cleanup()


def is_tcp_reachable(host: str, port: int, timeout: float = tcp_probe_timeout) -> bool:
    """Check if TCP socket is reachable"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        return True
    except Exception:
        return False
    finally:
        sock.close()


def tcp_socket_status(process: Optional[str], ports: Set[int]) -> int:
    """Check the TCP socket status for specific target ports on a process"""
    for p in psutil.process_iter():
        try:
            with p.oneshot():
                if process in " ".join(p.cmdline()):
                    pcon = p.net_connections()
                    for con in pcon:
                        try:
                            rport = con.raddr[1]
                            status = con.status
                        except IndexError:
                            # Skip if raddr is empty tuple: connection is not ESTABLISED or connection is LISTEN
                            continue
                        if rport in ports and status == tcp_established:
                            return 1
        except psutil.Error:
            continue
    return 0


def check_tcp_socket(
    service: str,
    rabbits: Set[Tuple[str, int]],
    databases: Set[Tuple[str, int]],
) -> None:
    """Check TCP socket to RabbitMQ/DB is in ESTABLISHED state"""
    dict_services = {
        "central": "designate-central",
        "producer": "designate-producer",
        "worker": "designate-worker",
        "mdns": "designate-mdns",
    }

    r_ports, d_ports = {port for _, port in rabbits}, {port for _, port in databases}

    if service in dict_services:
        proc = dict_services[service]
        if r_ports and tcp_socket_status(proc, r_ports) == 0:
            sys.stderr.write(f"RabbitMQ socket not established for service {proc}")
            # Do not kill the pod if RabbitMQ is not reachable/down
            if not cfg.CONF.liveness_probe:
                sys.exit(1)

        # let's do the db check
        # producer, mdns services do not have a direct db connection:
        if service not in ["producer", "mdns"]:
            if d_ports and tcp_socket_status(proc, d_ports) == 0:
                sys.stderr.write(f"Database socket not established for service {proc}")
                # Do not kill the pod if database is not reachable/down
                # there could be no socket as well as typically connections
                # get closed after an idle timeout
                # Just log it to pod events
                if not cfg.CONF.liveness_probe:
                    sys.exit(1)


def check_tcp_connectivity(
    rabbits: Set[Tuple[str, int]],
    databases: Set[Tuple[str, int]],
) -> None:
    """Check TCP connectivity to RabbitMQ/DB"""
    for host, port in databases:
        if not is_tcp_reachable(host, port):
            sys.stderr.write(f"Database not reachable from service")
            # Do not kill the pod if database is not reachable/down
            if not cfg.CONF.liveness_probe:
                sys.exit(1)
    for host, port in rabbits:
        if not is_tcp_reachable(host, port):
            sys.stderr.write(f"RabbitMQ not reachable from service")
            # Do not kill the pod if database is not reachable/down
            if not cfg.CONF.liveness_probe:
                sys.exit(1)


def configured_services_in_conf() -> Tuple[Set[Tuple[str, int]], Set[Tuple[str, int]]]:
    """Get the rabbitmq/db port configured in config file"""

    rabbits: Set[Tuple[str, int]] = set()
    databases: Set[Tuple[str, int]] = set()

    try:
        transport_url = oslo_messaging.TransportURL.parse(cfg.CONF)
        for host in transport_url.hosts:
            rabbits.add((host.hostname, host.port))
    except Exception as ex:
        message = getattr(ex, "message", str(ex))
        sys.stderr.write("Health probe caught exception reading RabbitMQs: %s" % message)

    try:
        url = make_url(cfg.CONF["storage:sqlalchemy"].connection)
        databases.add((url.host, url.port or 3306))
    except Exception as ex:
        message = getattr(ex, "message", str(ex))
        sys.stderr.write("Health probe caught exception reading DBs: %s" % message)

    return rabbits, databases


def test_liveness() -> None:
    """Test if service can connect to dependency services and can consume message from queue"""
    oslo_messaging.set_transport_defaults(control_exchange="designate")

    # workaround oslo.messaging always starting metrics thread
    metrics_group = cfg.OptGroup(name="oslo_messaging_metrics")
    cfg.CONF.register_group(metrics_group)
    cfg.CONF.set_override("metrics_enabled", False, metrics_group)
    cfg.CONF.set_override("metrics_thread_stop_timeout", 0, metrics_group)

    rabbit_group = cfg.OptGroup(name="oslo_messaging_rabbit", title="RabbitMQ options")
    cfg.CONF.register_group(rabbit_group)

    cfg.CONF.register_cli_opt(cfg.StrOpt("service-name"))
    cfg.CONF.register_cli_opt(cfg.BoolOpt("liveness-probe", default=False, required=False))
    cfg.CONF.register_cli_opt(cfg.StrOpt("host", default=None))

    cfg.CONF(sys.argv[1:])

    database_group = cfg.OptGroup(name="storage:sqlalchemy", title="Database options")
    cfg.CONF.register_group(database_group)
    cfg.CONF.register_opt(cfg.StrOpt("connection"), group=database_group)

    log.logging.basicConfig(level=log.INFO)

    try:
        transport = oslo_messaging.get_rpc_transport(cfg.CONF)
    except Exception as ex:
        message = getattr(ex, "message", str(ex))
        sys.stderr.write("Message bus driver load error: %s" % message)
        sys.exit(0)  # return success

    if not cfg.CONF.transport_url or not cfg.CONF.service_name:
        sys.stderr.write("Both message bus URL and service's name are required for health probe to work")
        sys.exit(0)  # return success

    service = cfg.CONF.service_name

    rabbits, databases = configured_services_in_conf()

    api_services = ["api"]
    rpc_services = ["central", "producer", "worker", "mdns"]

    if service in rpc_services:
        check_tcp_socket(service, rabbits, databases)
        if service not in "mdns":
            check_service_status(transport)

    if service in api_services:
        check_tcp_connectivity(rabbits, databases)


def check_pid_running(pid: int) -> bool:
    if psutil.pid_exists(pid):
        return True
    else:
        return False


if __name__ == "__main__":

    if "liveness-probe" in ",".join(sys.argv):
        pidfile = "/tmp/liveness.pid"  # nosec
    else:
        pidfile = "/tmp/readiness.pid"  # nosec
    data = {}
    if os.path.isfile(pidfile):
        with open(pidfile, "r") as f:
            file_content = f.read().strip()
            if file_content:
                data = json.loads(file_content)

    if "pid" in data and check_pid_running(int(data["pid"])):
        if "exit_count" in data and data["exit_count"] > 1:
            # Third time in, kill the previous process
            os.kill(int(data["pid"]), signal.SIGTERM)
        else:
            data["exit_count"] = data.get("exit_count", 0) + 1
            with open(pidfile, "w") as f:
                json.dump(data, f)
            sys.exit(0)
    data["pid"] = os.getpid()
    data["exit_count"] = 0
    with open(pidfile, "w") as f:
        json.dump(data, f)

    test_liveness()

    sys.exit(0)  # return success
