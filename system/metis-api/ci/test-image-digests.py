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
PIN_KEY = "metisAPI.imageTag"
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


def deployments(documents):
    return [doc for doc in documents if doc.get("kind") == "Deployment" and doc["metadata"]["name"] == "metis-api"]


def check(documents, pin, label):
    validate(documents)
    resources = deployments(documents)
    assert len(resources) == 1
    doc = resources[0]
    assert doc["metadata"]["labels"][LABEL] == label
    assert doc["spec"]["template"]["metadata"]["labels"][LABEL] == label
    assert doc["spec"]["template"]["spec"]["containers"][0]["image"] == "my-docker-registry/metis-api:" + pin


def baseline(ref):
    relative = CHART.relative_to(ROOT)
    archive = subprocess.check_output(["git", "-C", str(ROOT), "archive", ref, str(relative)])
    with tempfile.TemporaryDirectory(prefix="metis-api-image-baseline-") as temp:
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
    check(ordinary, "v1.2.3", "v1.2.3")
    assert ordinary == baseline(args.baseline_ref), "ordinary manifests changed from original baseline"
    pinned = render("image-digests-values.yaml")
    check(pinned, "v1.2.3@sha256:" + "1" * 64, "v1.2.3")
    assert unpin(pinned) == ordinary, "pinning changed more than container images"
    for tag in ["build", "123", "v" + "x" * 127, "_" + "x" * 61 + "_tail", "__"]:
        label = re.sub(r"[^A-Za-z0-9_.-]", "_", tag)[:63].strip("_.-")
        plain = render("image-tags-values.yaml", {PIN_KEY: tag})
        check(plain, tag, label)
        for digit in "12":
            pin = tag + "@sha256:" + digit * 64
            documents = render("image-tags-values.yaml", {PIN_KEY: pin})
            check(documents, pin, label)
            assert unpin(documents) == plain
    disabled = render("image-digests-values.yaml", {"metisAPI.enabled": False})
    validate(disabled)
    assert not deployments(disabled)
    print("PASS: original baseline, full-chart ordinary/pinned, Deployment/Pod labels, bounded labels, digest changes and disabled API")


if __name__ == "__main__":
    main()
