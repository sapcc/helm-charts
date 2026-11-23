#!/usr/bin/env python3
"""Integrated regression checks; requires Helm and Mike Farah yq.

Run from any directory. Pass --baseline-chart /path/to/original/common/rabbitmq
to also compare ordinary output with the original chart (except chart version).
"""
import argparse
import copy
import json
from pathlib import Path
import re
import subprocess


CHART = Path(__file__).resolve().parents[1]
DIGEST = "sha256:" + "1" * 64
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]*[A-Za-z0-9])?)?")


def yaml_documents(text):
    stream = subprocess.run(
        ["yq", "eval-all", "-o=json", "-I=0", ".", "-"],
        input=text, text=True, check=True, capture_output=True,
    ).stdout
    decoder = json.JSONDecoder()
    documents = []
    while stream.strip():
        document, end = decoder.raw_decode(stream.lstrip())
        if document is not None:
            documents.append(document)
        stream = stream.lstrip()[end:]
    return documents


def render(kind, fixture="image-tags", overrides=None, chart=CHART):
    command = ["helm", "template", "digest-test", str(chart), "-f",
               str(CHART / "ci" / (fixture + "-values.yaml")), "--set-string", f"kind={kind}"]
    for key, value in (overrides or {}).items():
        flag = "--set" if isinstance(value, bool) else "--set-string"
        command += [flag, f"{key}={str(value).lower() if isinstance(value, bool) else value}"]
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    text = result.stdout
    return yaml_documents(text), text


def objects(node):
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from objects(value)
    elif isinstance(node, list):
        for value in node:
            yield from objects(value)


def validate(documents, expected_version, kind):
    versions = []
    for node in objects(documents):
        for value in node.get("metadata", {}).get("labels", {}).values():
            assert isinstance(value, str) and len(value) <= 63 and LABEL.fullmatch(value), value
        labels = node.get("labels", {})
        if "app.kubernetes.io/version" in labels:
            versions.append(labels["app.kubernetes.io/version"])
    assert versions and all(value == expected_version for value in versions), versions
    workload = next(doc for doc in documents if doc.get("kind", "").lower() == kind)
    assert workload["metadata"]["labels"]["app.kubernetes.io/version"] == expected_version
    pod_labels = workload["spec"]["template"]["metadata"]["labels"]
    if kind == "statefulset":
        assert pod_labels["app.kubernetes.io/version"] == expected_version
    else:
        # The Deployment pod intentionally omits version metadata.
        assert "app.kubernetes.io/version" not in pod_labels


def images(documents):
    return [node["image"] for node in objects(documents) if "image" in node]


def assert_image_pin(documents, expected):
    repository = expected.split("@", 1)[0].rsplit(":", 1)[0]
    matching = [image for image in images(documents) if image.startswith(repository + ":")]
    assert matching and all(image == expected for image in matching), matching


def normalized(documents, strip_pins=False, strip_chart_version=False):
    result = copy.deepcopy(documents)
    for node in objects(result):
        if strip_pins and "image" in node:
            node["image"] = node["image"].split("@", 1)[0]
        if strip_chart_version:
            node.pop("helm.sh/chart", None)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-chart", type=Path)
    args = parser.parse_args()
    for kind in ["deployment", "statefulset"]:
        ordinary, _ = render(kind)
        pinned, _ = render(kind, "image-digests")
        validate(ordinary, "4.3.7", kind)
        validate(pinned, "4.3.7", kind)
        assert normalized(pinned, strip_pins=True) == ordinary, "Unexpected manifest changes with pins"
        assert_image_pin(pinned, "my.dockerhub.mirror/library/rabbitmq:4.3.7-management@" + DIGEST)
        assert_image_pin(pinned, "my.docker.registry/rabbitmq-user-credential-updater:20261026084952@" + DIGEST)
        if args.baseline_chart:
            baseline, _ = render(kind, chart=args.baseline_chart)
            assert normalized(baseline, strip_chart_version=True) == normalized(ordinary, strip_chart_version=True)
            print(f"PASS: {kind} ordinary output matches original chart except helm.sh/chart version")

        for tag, version in [("build", ""), ("1x2x3", ""), ("v12.34.56-management", "12.34.56")]:
            for suffix in ["", "@" + DIGEST, "@sha256:" + "2" * 64]:
                pin = tag + suffix
                rendered, text = render(kind, overrides={"imageTag": pin})
                validate(rendered, version, kind)
                assert_image_pin(rendered, "my.dockerhub.mirror/library/rabbitmq:" + pin)
                if not version:
                    assert re.search(r'app\.kubernetes\.io/version: ""\s*$', text, re.M), "Empty label must be quoted"
        disabled, _ = render(kind, "image-digests", {"credentialUpdater.enabled": False, "metrics.enabled": False})
        validate(disabled, "4.3.7", kind)
        assert not any("credential-updater" in image for image in images(disabled))
        regular, _ = render(kind, "image-digests", {"global.rabbitmq.native_sidecar.enabled": False})
        validate(regular, "4.3.7", kind)
        assert sorted(images(regular)) == sorted(images(pinned)), "Regular sidecars must also retain all pins"
        print(f"PASS: {kind} integrated pins, digest rotation, literal dots, empty labels, optional components")


if __name__ == "__main__":
    main()
