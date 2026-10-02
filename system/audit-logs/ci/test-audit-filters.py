#!/usr/bin/env python3
"""Run the rendered kube-api filters in real Logstash and Fluentd containers.

Requires Docker, Helm and yq v4. Supply the Fluentd image used by the deployment;
it must include fluent-plugin-multi-format-parser and fluent-plugin-record-modifier.
All input is synthetic. Containers have no network and only a read-only fixture mount.
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


def render(chart, key):
    document = run([
        "helm", "template", str(CHART / "vendor" / chart), "--show-only", "templates/configmap.yaml",
        "--set", "global.region=qa-de-1", "--set", "global.clusterType=admin", "--set", "global.cluster=review",
        "--set", "kubeAPIServer[0]=k-", "--set-json", "default_container_logs=[]",
    ])
    return run(["yq", f'.data."{key}"'], input=document)


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
        logstash_output = run(base + ["--memory", "1g", "-i", "-e", "LS_JAVA_OPTS=-Xms256m -Xmx256m",
            args.logstash_image, "--log.level", "error", "--pipeline.workers", "1",
            "--pipeline.ecs_compatibility", "disabled", "-f", "/review/logstash.conf"],
            input=json.dumps({"tags": ["kube-api"], "items": [event for event, _, _ in cases]}) + "\n", timeout=120, include_stderr=True)
        verify("logstash", logstash_output, cases)

        fluent = render("fluent-audit-container", "fluent.conf")
        source = re.search(r"<source>\n  @type tail\n  @id k-kube-api\n.*?</source>", fluent, re.S).group()
        source = re.sub(r"  path [^\n]+", "  path /review/events.log\n  read_from_head true\n  refresh_interval 1", source)
        source = re.sub(r"  pos_file [^\n]+", "  pos_file /tmp/audit-review.pos", source)
        filters = re.findall(r"<filter kubeapi\.[^>]*>.*?</filter>", fluent, re.S)
        assert len(filters) == 4, "Expected cluster metadata, parser, credential and label filters"
        (root / "fluent.conf").write_text('<system>\n  log_level warn\n</system>\n' + source + '\n' + '\n'.join(filters)
            + '\n<match kubeapi.**>\n  @type stdout\n  <format>\n    @type json\n  </format>\n</match>\n')
        (root / "events.log").write_text("".join(f"{STAMP} stdout F {json.dumps(event)}\n" for event, _, _ in cases))
        fluent_output = run(base + ["--memory", "512m", "--entrypoint", "/bin/sh", args.fluentd_image, "-c",
            'fluentd --no-supervisor -c /review/fluent.conf & audit_pid=$!; sleep 8; kill -TERM "$audit_pid"; wait "$audit_pid"'], timeout=60, include_stderr=True)
        assert "[warn]" not in fluent_output and "[error]" not in fluent_output, fluent_output
        verify("fluentd", fluent_output, cases)


if __name__ == "__main__":
    main()
