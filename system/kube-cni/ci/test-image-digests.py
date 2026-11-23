#!/usr/bin/env python3
"""Run from any directory; requires Helm and yq v4. No chart dependencies."""

import argparse
from contextlib import contextmanager
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile


CHART = Path(__file__).resolve().parents[1]
ROOT = CHART.parents[1]
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


def check(documents, pin, enabled):
    validate(documents)
    daemonsets = [doc for doc in documents if doc.get("kind") == "DaemonSet"]
    assert len(daemonsets) == 1
    pod = daemonsets[0]["spec"]["template"]["spec"]
    multus = [container for container in pod["initContainers"] if container["name"] == "install-multus-cni-plugin"]
    assert len(multus) == int(enabled)
    if enabled:
        tag = pin.split("@", 1)[0]
        source = "/multus-cni/multus-cni" if tag == "v3" else "/multus-cni/multus"
        assert multus[0]["image"] == "registry.example.test/multus-cni:" + pin
        assert multus[0]["command"] == ["cp"]
        assert multus[0]["args"] == ["-f", source, "/opt/cni/bin/multus-cni"]
    return pod


@contextmanager
def baseline(ref):
    relative = CHART.relative_to(ROOT)
    archive = subprocess.check_output(["git", "-C", str(ROOT), "archive", ref, str(relative)])
    with tempfile.TemporaryDirectory(prefix="kube-cni-image-baseline-") as temp:
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar.getmembers():
                assert not member.name.startswith("/") and ".." not in Path(member.name).parts
                assert member.isfile() or member.isdir()
            tar.extractall(temp)
        chart = Path(temp) / relative
        # Align only the intentional chart-version bump, retaining original templates.
        version = re.search(r"^version: (.+)$", (CHART / "Chart.yaml").read_text(), re.M).group(1)
        metadata = chart / "Chart.yaml"
        metadata.write_text(re.sub(r"^version: .+$", "version: " + version, metadata.read_text(), flags=re.M))
        yield chart


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", default=BASE)
    args = parser.parse_args()
    with baseline(args.baseline_ref) as original:
        for enabled in [False, True]:
            for tag in ["v3", "v4", "v4.2.0"]:
                settings = {"plugins.multus": enabled, "images.multus.tag": tag}
                ordinary = render("image-tags-values.yaml", settings)
                check(ordinary, tag, enabled)
                assert ordinary == render("image-tags-values.yaml", settings, original), "ordinary manifests changed from original baseline"
                for digit in "12":
                    pin = tag + "@sha256:" + digit * 64
                    pinned = render("image-digests-values.yaml", {"plugins.multus": enabled, "images.multus.tag": pin})
                    check(pinned, pin, enabled)
                    assert unpin(pinned) == ordinary, "pinning changed binary selection or other output"
    ordinary = render("image-tags-values.yaml")
    pinned = render("image-digests-values.yaml")
    check(pinned, "v4@sha256:" + "1" * 64, True)
    assert unpin(pinned) == ordinary
    settings = {"images." + name + ".tag": tag + "@sha256:" + "2" * 64 for name, tag in [("cni", "v1.2.3"), ("pause", "3.9"), ("flannel", "v1.5.1")]}
    all_pinned = render("image-digests-values.yaml", settings)
    pod = check(all_pinned, "v4@sha256:" + "1" * 64, True)
    assert all("@sha256:" in container["image"] for container in pod["initContainers"] + pod["containers"])
    assert unpin(all_pinned) == ordinary
    disabled_flannel = render("image-digests-values.yaml", {"plugins.flannel": False})
    pod = check(disabled_flannel, "v4@sha256:" + "1" * 64, True)
    assert all(container["name"] != "install-flannel-cni-plugin" for container in pod["initContainers"])
    print("PASS: original baseline, v3/v4/v4.2.0 ordinary/pinned and enabled/disabled, digest changes, binary paths and all image pins")


if __name__ == "__main__":
    main()
