#!/usr/bin/env python3
"""Run the rendered kube-api filters in real Logstash and Fluentd containers.

Requires Docker, Helm and yq v4. Supply the Fluentd image used by the deployment;
it must include fluent-plugin-multi-format-parser, fluent-plugin-record-modifier and
fluent-plugin-prometheus. All input is synthetic. Containers have no network and only a
read-only fixture mount. Also checks that each collector counts the events whose
credential bodies it removed, and that the alert rules on those counters are valid.
"""

import argparse
import copy
import json
from pathlib import Path
import re
import subprocess
import tempfile

CHART = Path(__file__).resolve().parents[1]
STAMP = "2026-01-01T12:00:00.000000Z"
SECRET = "SYNTHETIC_CREDENTIAL_MUST_BE_REMOVED"
PATCH_PREFIX = "patch.webhook.admission.k8s.io/"
MARKER = "sap.cc.audit.credential_body_removed"
LOGSTASH_PLUGIN_ID = "audit_credential_body_removed"
FLUENT_METRIC = "fluentd_audit_kubeapi_credential_body_removed_total"
MUTATION = "mutation.webhook.admission.k8s.io/round_0_index_0"
ANNOTATIONS = {
    "shoot.gardener.cloud/name": "review-qa-de-1",
    "seed.gardener.cloud/name": "review-seed",
    "authorization.k8s.io/decision": "allow",
    MUTATION: '{"mutated":true}',
}


def fixtures():
    cases = []

    def add(name, resource=None, subresource=None, request=None, response=None, sensitive=False, patch=False):
        event = {
            "kind": "Event", "apiVersion": "audit.k8s.io/v1", "auditID": name,
            "level": "RequestResponse", "stage": "ResponseComplete", "verb": "create",
            "requestReceivedTimestamp": STAMP, "stageTimestamp": STAMP,
            "user": {"username": "synthetic-review"}, "annotations": copy.deepcopy(ANNOTATIONS),
        }
        if resource:
            event["objectRef"] = {"resource": resource, "name": "synthetic", "namespace": "review"}
            if subresource:
                event["objectRef"]["subresource"] = subresource
        if request is not None:
            event["requestObject"] = request
        if response is not None:
            event["responseObject"] = response
        if patch:
            for suffix in ("round_0_index_0", "round_1_index_2"):
                event["annotations"][PATCH_PREFIX + suffix] = json.dumps({
                    "patchType": "JSONPatch", "patch": [{"op": "add", "path": "/data/password", "value": SECRET}],
                })
        if request is None and response is None:
            event["level"] = "Metadata"
        # The marker flags credential content on credential-bearing requests only; patch
        # annotations on other objects are removed without it, because webhooks patch
        # ordinary objects (shoots, pods) all the time.
        cases.append((event, sensitive, sensitive and (patch or request is not None or response is not None)))

    add("secret-create", "secrets", request={"stringData": {"password": SECRET}, "metadata": {
        "annotations": {"kubectl.kubernetes.io/last-applied-configuration": SECRET}}}, sensitive=True)
    add("secret-get", "secrets", response={"data": {"password": SECRET}}, sensitive=True)
    add("secret-list", "secrets", response={"items": [{"data": {"password": SECRET}}]}, sensitive=True)
    add("secret-json-patch", "secrets", request=[{"op": "add", "path": "/data/password", "value": SECRET}], sensitive=True)
    add("token-review", "tokenreviews", request={"spec": {"token": SECRET}}, sensitive=True)
    add("sa-token", "serviceaccounts", "token", response={"status": {"token": SECRET}}, sensitive=True)
    add("workload-token", "workloadidentities", "token", response={"status": {"token": SECRET}}, sensitive=True)
    for subresource in ("adminkubeconfig", "viewerkubeconfig"):
        add(subresource, "shoots", subresource, response={"status": {"kubeconfig": SECRET}}, sensitive=True)
    for resource in ("bmcsecrets", "internalsecrets"):
        add(resource, resource, request={"data": {"password": SECRET}}, sensitive=True)
    add("body-and-annotations", "secrets", request={"data": {"password": SECRET}}, sensitive=True, patch=True)
    add("annotations-only", "secrets", sensitive=True, patch=True)
    add("pod-annotations", "pods", request={"spec": {"containers": []}}, patch=True)
    add("shoot-update-annotations", "shoots", request={"spec": {"purpose": "evaluation"}}, patch=True)
    add("metadata-control", "secrets", sensitive=True)
    add("shoot-control", "shoots", request={"spec": {"purpose": "testing"}})
    add("configmap-control", "configmaps", request={"data": {"safe": "value"}})
    add("rbac-json-patch", "clusterrolebindings", request=[{"op": "add", "path": "/subjects/-", "value": {"name": "review"}}])
    add("non-resource-control")
    return cases


def run(command, *, include_stderr=False, **kwargs):
    result = subprocess.run(command, text=True, capture_output=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"Command failed: {command}\n{result.stdout}\n{result.stderr}")
    return result.stdout + (result.stderr if include_stderr else "")


def render(chart, key=None, template="templates/configmap.yaml"):
    document = run([
        "helm", "template", str(CHART / "vendor" / chart), "--show-only", template,
        "--set", "global.region=qa-de-1", "--set", "global.clusterType=admin", "--set", "global.cluster=review",
        "--set", "kubeAPIServer[0]=k-", "--set-json", "default_container_logs=[]", "--set", "alerts.enabled=true",
    ])
    return run(["yq", f'.data."{key}"' if key else ".spec"], input=document)


def logstash_counter(output):
    """events.out of the filter step that removes credential bodies, from the node stats API."""
    line = next(line for line in output.splitlines() if line.startswith("LOGSTASH_STATS "))
    filters = json.loads(line.split(" ", 1)[1])["pipelines"]["main"]["plugins"]["filters"]
    return next(step["events"]["out"] for step in filters if step.get("id") == LOGSTASH_PLUGIN_ID)


def fluent_counter(output):
    """Sum of the credential-removal counter scraped from Fluentd's Prometheus endpoint."""
    block = output.split("FLUENT_METRICS_BEGIN", 1)[1].split("FLUENT_METRICS_END", 1)[0]
    total = 0.0
    for line in block.splitlines():
        if line.startswith(FLUENT_METRIC + "{"):
            assert 'cluster="k-qa-de-1"' in line, line
            total += float(line.rsplit(" ", 1)[1])
    return total


def output_events(text):
    events = []
    for line in text.splitlines():
        start = line.find("{")
        if start < 0:
            continue
        try:
            event = json.loads(line[start:])
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict) and "auditID" in event:
            events.append(event)
    return events


def verify(name, output, cases):
    assert SECRET not in output, f"{name}: credential appeared in output or diagnostics"
    events = output_events(output)
    assert len(events) == len(cases), f"{name}: expected {len(cases)} events, got {len(events)}\n{output}"
    actual = {event["auditID"]: event for event in events}
    assert len(actual) == len(cases), f"{name}: duplicate events"
    for before, sensitive, marked in cases:
        event = actual[before["auditID"]]
        assert event.get("annotations") == ANNOTATIONS, (name, before["auditID"], "annotations")
        marker = event.get(MARKER) if name == "fluentd" else event.get("sap", {}).get("cc", {}).get("audit", {}).get("credential_body_removed")
        assert marker is (True if marked else None), (name, before["auditID"], "marker must be a boolean")
        for key in ("requestObject", "responseObject"):
            if sensitive:
                assert key not in event, (name, before["auditID"], key)
            else:
                assert event.get(key) == before.get(key), (name, before["auditID"], key)
        for key in ("objectRef", "user", "verb", "stage", "requestReceivedTimestamp"):
            assert event.get(key) == before.get(key), (name, before["auditID"], key)
    print(f"{name}: {len(cases)} events passed; bodies and patch annotations removed, metadata preserved")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fluentd-image", required=True)
    parser.add_argument("--logstash-image", default="docker.elastic.co/logstash/logstash-oss:8.15.3")
    parser.add_argument("--prometheus-image", default="prom/prometheus:v2.53.2")
    args = parser.parse_args()
    cases = fixtures()
    with tempfile.TemporaryDirectory(prefix="audit-filter-tests-") as directory:
        root = Path(directory)
        root.chmod(0o755)  # Collector images may run as an unprivileged user.
        # Use the whole rendered kube-api block, with synthetic stdin/stdout transports.
        logstash = render("logstash-audit-external", "logstash.conf")
        start = logstash.index('    if ("kube-api" in [tags]) {')
        end = logstash.index("\n      }\n\n\noutput {", start)
        (root / "logstash.conf").write_text(
            'input { stdin { codec => json } }\nfilter {\n' + logstash[start:end]
            + '\n}\noutput { stdout { codec => json_lines } }\n'
        )
        base = ["docker", "run", "--rm", "--network", "none", "--cap-drop", "ALL", "--cpus", "2",
                "-v", f"{root}:/review:ro"]
        (root / "input.json").write_text(json.dumps({"tags": ["kube-api"], "items": [event for event, _, _ in cases]}) + "\n")
        # Keep stdin open so the node stats API can be read once every event is out.
        logstash_script = (
            "(cat /review/input.json; sleep 120) | /usr/share/logstash/bin/logstash --log.level error"
            " --pipeline.workers 1 --pipeline.ecs_compatibility disabled"
            " -f /review/logstash.conf & ls_pid=$!;"
            " for i in $(seq 90); do curl -fs 127.0.0.1:9600/_node/stats/pipelines/main > /tmp/stats"
            f" && grep -q '\"out\":{len(cases)}[,}}]' /tmp/stats && break; sleep 1; done; sleep 2;"
            " curl -fs 127.0.0.1:9600/_node/stats/pipelines/main > /tmp/stats;"
            ' printf "LOGSTASH_STATS %s\\n" "$(cat /tmp/stats)"; kill "$ls_pid"; wait "$ls_pid"; true'
        )
        # The stats API resolves the container's own hostname, so use one /etc/hosts knows.
        logstash_output = run(base + ["--memory", "1g", "--hostname", "localhost", "-e", "LS_JAVA_OPTS=-Xms256m -Xmx256m",
            "--entrypoint", "/bin/sh", args.logstash_image, "-c", logstash_script], timeout=180, include_stderr=True)
        verify("logstash", logstash_output, cases)
        marked = sum(1 for _, _, is_marked in cases if is_marked)
        assert logstash_counter(logstash_output) == marked, ("logstash counter", logstash_counter(logstash_output), marked)
        print(f"logstash: the {LOGSTASH_PLUGIN_ID} step counted {marked} events")

        fluent = render("fluent-audit-container", "fluent.conf")
        source = re.search(r"<source>\n  @type tail\n  @id k-kube-api\n.*?</source>", fluent, re.S).group()
        source = re.sub(r"  path [^\n]+", "  path /review/events.log\n  read_from_head true\n  refresh_interval 1", source)
        source = re.sub(r"  pos_file [^\n]+", "  pos_file /tmp/audit-review.pos", source)
        filters = re.findall(r"<filter kubeapi\.[^>]*>.*?</filter>", fluent, re.S)
        assert len(filters) == 6, "Expected cluster metadata, parser, credential, counter, counter cleanup and label filters"
        metrics = '<source>\n  @type prometheus\n  bind 127.0.0.1\n  port 24231\n</source>\n'
        (root / "fluent.conf").write_text('<system>\n  log_level warn\n</system>\n' + source + '\n' + metrics + '\n'.join(filters)
            + '\n<match kubeapi.**>\n  @type stdout\n  <format>\n    @type json\n  </format>\n</match>\n')
        (root / "events.log").write_text("".join(f"{STAMP} stdout F {json.dumps(event)}\n" for event, _, _ in cases))
        fluent_output = run(base + ["--memory", "512m", "--entrypoint", "/bin/sh", args.fluentd_image, "-c",
            'fluentd --no-supervisor -c /review/fluent.conf & audit_pid=$!; sleep 8; '
            'ruby -rnet/http -e \'puts "FLUENT_METRICS_BEGIN", Net::HTTP.get(URI("http://127.0.0.1:24231/metrics")), "FLUENT_METRICS_END"\'; '
            'kill -TERM "$audit_pid"; wait "$audit_pid"'], timeout=60, include_stderr=True)
        assert "[warn]" not in fluent_output and "[error]" not in fluent_output, fluent_output
        verify("fluentd", fluent_output, cases)
        assert fluent_counter(fluent_output) == marked, ("fluentd counter", fluent_counter(fluent_output), marked)
        print(f"fluentd: {FLUENT_METRIC} counted {marked} events")

        # The alert rules on these counters must be valid Prometheus rules.
        (root / "logstash.rules.yaml").write_text(render("logstash-audit-external", template="templates/prometheus-alerts.yaml"))
        (root / "fluent.rules.yaml").write_text(render("fluent-audit-container", template="templates/prometheus-alerts-kube-audit.yaml"))
        print(run(base + ["--entrypoint", "/bin/promtool", args.prometheus_image, "check", "rules",
            "/review/logstash.rules.yaml", "/review/fluent.rules.yaml"], include_stderr=True).strip())


if __name__ == "__main__":
    main()
