#!/usr/bin/env python3
"""Integrated regression checks; requires Helm and Mike Farah yq.

Run from any directory. Pass --baseline-chart /path/to/original/common/memcached
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


def render(fixture="image-tags", overrides=None, chart=CHART):
    command = ["helm", "template", "digest-test", str(chart), "-f",
               str(CHART / "ci" / (fixture + "-values.yaml"))]
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


def validate(documents, expected_version):
    versions = []
    for node in objects(documents):
        for value in node.get("metadata", {}).get("labels", {}).values():
            assert isinstance(value, str) and len(value) <= 63 and LABEL.fullmatch(value), value
        labels = node.get("labels", {})
        if "app.kubernetes.io/version" in labels:
            versions.append(labels["app.kubernetes.io/version"])
    assert versions and all(value == expected_version for value in versions), versions
    deployment = next(doc for doc in documents if doc.get("kind") == "Deployment")
    assert deployment["spec"]["template"]["metadata"]["labels"]["app.kubernetes.io/version"] == expected_version


def images(documents):
    return [node["image"] for node in objects(documents) if "image" in node]


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
    ordinary, _ = render()
    pinned, _ = render("image-digests")
    validate(ordinary, "1.6.45")
    validate(pinned, "1.6.45")
    assert normalized(pinned, strip_pins=True) == ordinary, "Unexpected manifest changes with pins"
    assert "my.dockerhub.mirror/library/memcached:1.6.45-alpine3.24@" + DIGEST in images(pinned)
    assert "my.dockerhub.mirror/prom/memcached-exporter:v0.17.0@" + DIGEST in images(pinned)
    if args.baseline_chart:
        baseline, _ = render(chart=args.baseline_chart)
        assert normalized(baseline, strip_chart_version=True) == normalized(ordinary, strip_chart_version=True)
        print("PASS: ordinary output matches original chart except helm.sh/chart version")

    for tag, version in [("build", ""), ("1x2x3", ""), ("v12.34.56-alpine", "12.34.56")]:
        for suffix in ["", "@" + DIGEST, "@sha256:" + "2" * 64]:
            pin = tag + suffix
            rendered, text = render(overrides={"imageTag": pin})
            validate(rendered, version)
            assert "my.dockerhub.mirror/library/memcached:" + pin in images(rendered)
            if not version:
                assert re.search(r'app\.kubernetes\.io/version: ""\s*$', text, re.M), "Empty label must be quoted"
    disabled, _ = render("image-digests", {"metrics.enabled": False})
    validate(disabled, "1.6.45")
    assert not any("memcached-exporter" in image for image in images(disabled))
    print("PASS: integrated ordinary/pinned, digest rotation, literal dots, empty labels, metrics enabled/disabled")


if __name__ == "__main__":
    main()
