# Copyright 2024 The Openstack-Helm Authors.
#
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

# WSGI worker-pool sampler.
#
# This module is loaded into every mod_wsgi daemon process via
# WSGIImportScript. Because it runs *inside* the daemon interpreter, it can
# call mod_wsgi.process_metrics() to read that process's own state. Each
# process pushes its current "active_requests" (0 or 1, since keystone runs
# with threads=1) to statsd as a gauge labelled by pid. The statsd-exporter
# sidecar turns these into Prometheus series; summing across pids yields the
# pool-wide busy worker count, and (processes - busy) yields the free count.

import os
import socket
import threading
import time

try:
    import mod_wsgi
except ImportError:
    mod_wsgi = None


# How often (seconds) each process samples and reports its state.
SAMPLE_INTERVAL = float(os.environ.get("WSGI_SAMPLER_INTERVAL", "2"))

STATSD_HOST = os.environ.get("STATSD_HOST", "127.0.0.1")
STATSD_PORT = int(os.environ.get("STATSD_PORT", "9125"))
STATSD_PREFIX = os.environ.get("STATSD_PREFIX", "openstack")


def _send(sock, metric, value):
    """Send a single statsd gauge datagram; never raise into the caller."""
    try:
        payload = "%s:%d|g" % (metric, value)
        sock.sendto(payload.encode("utf-8"), (STATSD_HOST, STATSD_PORT))
    except Exception:
        # Sampling must never affect request serving.
        pass


def _loop():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    while True:
        try:
            metrics = mod_wsgi.process_metrics()
            pid = metrics["pid"]
            active = int(metrics.get("active_requests", 0))
            # Metric name carries the pid so the statsd-exporter can map it to
            # a Prometheus label. Sum across pids = busy workers.
            metric = "%s.wsgi.worker.active_requests.%s" % (STATSD_PREFIX, pid)
            _send(sock, metric, active)
        except Exception:
            pass
        time.sleep(SAMPLE_INTERVAL)


def start():
    if mod_wsgi is None:
        # Not running under mod_wsgi (e.g. imported elsewhere); do nothing.
        return
    thread = threading.Thread(target=_loop, name="wsgi-worker-sampler")
    thread.daemon = True
    thread.start()


start()
