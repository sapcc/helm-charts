#!/usr/bin/env python3
"""Run from any directory; requires Helm, yq v4 and real chart dependencies."""

import argparse
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile


CHART = Path(__file__).resolve().parents[1]
ROOT = CHART.parents[1]
LABEL = "app.kubernetes.io/version"
BASE = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"


def render(fixture, settings=None, chart=CHART):
    command = ["helm", "template", "digest-regression", str(chart), "-f", str(CHART / "ci" / fixture)]
    for key, value in (settings or {}).items():
        command += ["--set-json", key + "=" + json.dumps(value)]
    yaml = subprocess.check_output(command, text=True)
    data = subprocess.check_output(["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=yaml, text=True)
    decoder = json.JSONDecoder()
    documents = []
    while data.strip():
        document, end = decoder.raw_decode(data.lstrip())
        if document is not None:
            documents.append(document)
        data = data.lstrip()[end:]
    return documents


def validate(node):
    if isinstance(node, dict):
        labels = node.get("metadata", {}).get("labels") if isinstance(node.get("metadata"), dict) else None
        if isinstance(labels, dict):
            for key, value in labels.items():
                assert isinstance(value, str), (key, value)
                assert len(value) <= 63 and re.fullmatch(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]*[A-Za-z0-9])?)?", value), (key, value)
        for value in node.values():
            validate(value)
    elif isinstance(node, list):
        for value in node:
            validate(value)


def unpin(node):
    if isinstance(node, dict):
        return {key: value.split("@", 1)[0] if key == "image" and isinstance(value, str) else unpin(value) for key, value in node.items()}
    if isinstance(node, list):
        return [unpin(value) for value in node]
    return node


def version(pin):
    tag = pin.split("@", 1)[0]
    return re.sub(r"[^A-Za-z0-9_.-]", "_", tag)[:63].strip("_.-")


def workloads(documents, kind, name):
    return [doc for doc in documents if doc.get("kind") == kind and doc["metadata"]["name"] == name]


def check(documents, metis_pin="v1.2.3", sync_pin="20230425160817", metis_enabled=True, sync_enabled=True):
    validate(documents)
    deployments = workloads(documents, "Deployment", "metis")
    assert len(deployments) == int(metis_enabled)
    for doc in deployments:
        pod = doc["spec"]["template"]
        assert pod["metadata"]["labels"][LABEL] == version(metis_pin)
        assert pod["spec"]["containers"][0]["image"] == "my-registry/metis:" + metis_pin
    for backup in ["nova", "keystone"]:
        name = "mariadb-sync-" + backup
        services = workloads(documents, "Service", name)
        statefulsets = workloads(documents, "StatefulSet", name)
        assert len(services) == len(statefulsets) == int(sync_enabled)
        for service, statefulset in zip(services, statefulsets):
            assert service["metadata"]["labels"][LABEL] == version(sync_pin)
            assert statefulset["metadata"]["labels"][LABEL] == version(sync_pin)
            pod = statefulset["spec"]["template"]
            assert pod["metadata"]["labels"][LABEL] == version(sync_pin)
            assert pod["spec"]["containers"][0]["image"] == "my-registry/go-maria-sync:" + sync_pin
            assert statefulset["spec"]["serviceName"] == service["metadata"]["name"]
            for key, value in service["spec"]["selector"].items():
                assert pod["metadata"]["labels"][key] == value


def baseline(ref):
    relative = CHART.relative_to(ROOT)
    archive = subprocess.check_output(["git", "-C", str(ROOT), "archive", ref, str(relative)])
    with tempfile.TemporaryDirectory(prefix="metis-image-baseline-") as temp:
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar.getmembers():
                assert not member.name.startswith("/") and ".." not in Path(member.name).parts
                assert member.isfile() or member.isdir()
            tar.extractall(temp)
        chart = Path(temp) / relative
        shutil.copytree(CHART / "charts", chart / "charts", dirs_exist_ok=True)
        # Align only the intentional chart-version bump, retaining original templates.
        version = re.search(r"^version: (.+)$", (CHART / "Chart.yaml").read_text(), re.M).group(1)
        metadata = chart / "Chart.yaml"
        metadata.write_text(re.sub(r"^version: .+$", "version: " + version, metadata.read_text(), flags=re.M))
        return render("image-tags-values.yaml", chart=chart)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", default=BASE)
    args = parser.parse_args()
    ordinary = render("image-tags-values.yaml")
    check(ordinary)
    assert ordinary == baseline(args.baseline_ref), "ordinary manifests changed from original baseline"
    pinned = render("image-digests-values.yaml")
    check(pinned, "v1.2.3@sha256:" + "1" * 64, "20230425160817@sha256:" + "1" * 64)
    assert unpin(pinned) == ordinary, "pinning changed more than container images"
    for field in ["metis.imageTag", "metisSync.imageVersion"]:
        for tag in ["build", "123", "v" + "x" * 127, "_" + "x" * 61 + "_tail", "__"]:
            pins = {"metis_pin" if field == "metis.imageTag" else "sync_pin": tag}
            plain = render("image-tags-values.yaml", {field: tag})
            check(plain, **pins)
            for digit in "12":
                pin = tag + "@sha256:" + digit * 64
                pins["metis_pin" if field == "metis.imageTag" else "sync_pin"] = pin
                documents = render("image-tags-values.yaml", {field: pin})
                check(documents, **pins)
                assert unpin(documents) == plain
    for metis_enabled, sync_enabled in [(False, True), (True, False), (False, False)]:
        documents = render("image-digests-values.yaml", {"metis.enabled": metis_enabled, "metisSync.enabled": sync_enabled})
        check(documents, "v1.2.3@sha256:" + "1" * 64, "20230425160817@sha256:" + "1" * 64, metis_enabled, sync_enabled)
    print("PASS: original baseline, real MariaDB dependency, ordinary/pinned Metis and sync, Service/StatefulSet/Pod labels, digest changes and enabled/disabled components")


if __name__ == "__main__":
    main()
