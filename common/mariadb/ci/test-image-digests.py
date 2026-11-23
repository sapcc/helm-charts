#!/usr/bin/env python3
"""Integrated regression checks; requires Helm, Mike Farah yq and chart dependencies.

Run helm dependency build common/mariadb first, then run this script from any
directory. Pass --baseline-chart /path/to/original/common/mariadb to also compare
ordinary output with the original chart (except chart version).
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
JOB_NAME = re.compile(r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")


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
    return yaml_documents(result.stdout), result.stdout


def objects(node):
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from objects(value)
    elif isinstance(node, list):
        for value in node:
            yield from objects(value)


def validate(documents, expected_version, sync_version="20260813190947"):
    versions = []
    for node in objects(documents):
        for value in node.get("metadata", {}).get("labels", {}).values():
            assert isinstance(value, str) and len(value) <= 63 and LABEL.fullmatch(value), value
        labels = node.get("labels", {})
        if "app.kubernetes.io/version" in labels:
            expected = sync_version if labels.get("app.kubernetes.io/name") == "go-maria-sync" else expected_version
            assert labels["app.kubernetes.io/version"] == expected, labels
            versions.append(expected)
        if node.get("kind") == "Job":
            name = node["metadata"]["name"]
            assert len(name) <= 63 and JOB_NAME.fullmatch(name), name
    assert versions, "No version label consumers rendered"
    database = next(doc for doc in documents if doc.get("kind") == "Deployment" and doc["metadata"]["name"] == "test-mariadb")
    assert database["metadata"]["labels"]["app.kubernetes.io/version"] == expected_version
    # The database pod intentionally has no version metadata to avoid chart-only restarts.
    assert "app.kubernetes.io/version" not in database["spec"]["template"]["metadata"]["labels"]


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
    ordinary, _ = render()
    pinned, _ = render("image-digests")
    validate(ordinary, "10.11.19")
    validate(pinned, "10.11.19")
    assert normalized(pinned, strip_pins=True) == ordinary, "Unexpected manifest changes with pins"
    for expected in [
        "other.dockerhub.mirror/library/mariadb:10.11.19@" + DIGEST,
        "other.docker.registry/shared-app-images/alpine-mariadb:python3.13-alpine3.24-20260820144936@" + DIGEST,
        "my.docker.registry/shared-app-images/alpine-mariadb:python3.13-alpine3.24-20260820144936@" + DIGEST,
        "my.docker.registry/go-maria-sync:20260813190947@" + DIGEST,
    ]:
        assert_image_pin(pinned, expected)
    if args.baseline_chart:
        baseline, _ = render(chart=args.baseline_chart)
        assert normalized(baseline, strip_chart_version=True) == normalized(ordinary, strip_chart_version=True)
        print("PASS: ordinary output matches original chart except helm.sh/chart version")

    for tag, version in [("build", ""), ("1x2x3", ""), ("v12.34.56", "12.34.56")]:
        for suffix in ["", "@" + DIGEST, "@sha256:" + "2" * 64]:
            pin = "library/mariadb:" + tag + suffix
            rendered, text = render(overrides={"image": pin})
            validate(rendered, version)
            assert_image_pin(rendered, "other.dockerhub.mirror/" + pin)
            if not version:
                assert re.search(r'app\.kubernetes\.io/version: ""\s*$', text, re.M), "Empty label must be quoted"

    for tag in ["build", "sync-" + "a" * 100, "_sync." + "a" * 56 + ".tail", "_sync_"]:
        expected = re.sub(r"^[^A-Za-z0-9]+|[^A-Za-z0-9]+$", "", tag[:63])
        for suffix in ["", "@" + DIGEST, "@sha256:" + "2" * 64]:
            rendered, _ = render("image-digests", {"sync.image.tag": tag + suffix})
            validate(rendered, "10.11.19", expected)
            assert_image_pin(rendered, "my.docker.registry/go-maria-sync:" + tag + suffix)

    disabled, _ = render("image-digests", {"sync.enabled": False, "sync.init.enabled": False})
    validate(disabled, "10.11.19")
    assert not any("go-maria-sync" in image for image in images(disabled))
    regular, _ = render("image-digests", {"global.mariadb.native_sidecar.enabled": False})
    validate(regular, "10.11.19")
    assert sorted(images(regular)) == sorted(images(pinned)), "Regular sidecars must also retain all pins"
    print("PASS: integrated main/updater/sync/init pins, digest rotation, literal dots, empty labels, long sync tags, optional components")


if __name__ == "__main__":
    main()
