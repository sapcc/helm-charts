#!/usr/bin/env python3
"""Real-chart regression renders; requires Helm, Mike Farah yq, and optionally Git.

Run from the repository root or this chart:
  python3 <chart>/ci/test-image-digests.py --baseline-ref <original-git-ref>
"""

import argparse
import copy
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile


CHART = Path(__file__).resolve().parents[1]
TAG = "v0.40.0"
REPOSITORY = "registry.example.org:5000/team/thanos"
DIGEST = "sha256:" + "1" * 64
PIN = TAG + "@" + DIGEST
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]*[A-Za-z0-9])?)?")


def command(args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, **kwargs).stdout


def documents(yaml):
    text = command(["yq", "eval-all", "-o=json", "-I=0", ".", "-"],
                   input=yaml, text=True)
    decoder = json.JSONDecoder()
    result = []
    while text.strip():
        item, end = decoder.raw_decode(text.lstrip())
        if item:
            result.append(item)
        text = text.lstrip()[end:]
    return result


def render(fixture="image-digests-values.yaml", extra=None, chart=CHART,
           release="digest-test", error=None):
    with tempfile.TemporaryDirectory(prefix="prometheus-pre7-image-values-") as tmp:
        values = Path(tmp) / "values.json"
        values.write_text(json.dumps(extra or {}))
        args = ["helm", "template", release, str(chart), "-f",
                str(CHART / "ci" / fixture), "-f", str(values)]
        result = subprocess.run(args, capture_output=True, text=True)
        if error:
            assert result.returncode != 0, "expected render failure"
            assert error in result.stderr, result.stderr
            return
        assert result.returncode == 0, result.stderr
        result = documents(result.stdout)
        validate_metadata(result)
        return result


def validate_metadata(value):
    if isinstance(value, dict):
        for label in value.get("metadata", {}).get("labels", {}).values():
            assert isinstance(label, str) and len(label) <= 63 and LABEL.fullmatch(label), label
        if value.get("kind") == "Job":
            name = value["metadata"]["name"]
            assert len(name) <= 63 and re.fullmatch(r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?", name), name
        for item in value.values():
            validate_metadata(item)
    elif isinstance(value, list):
        for item in value:
            validate_metadata(item)


def thanos(manifests):
    return next(item["spec"]["thanos"] for item in manifests if item["kind"] == "Prometheus")


def component_images(manifests):
    result = {}
    for item in manifests:
        if item["kind"] in ("Deployment", "StatefulSet"):
            for container in item["spec"]["template"]["spec"]["containers"]:
                if container["name"].startswith("thanos-"):
                    result[container["name"]] = container["image"]
    assert set(result) == {"thanos-query", "thanos-compactor", "thanos-store"}, result
    return result


def baseline(ref):
    repo = Path(command(["git", "rev-parse", "--show-toplevel"],
                        cwd=CHART, text=True).strip())
    relative = str(CHART.relative_to(repo))
    archive = command(["git", "archive", ref, relative], cwd=repo)
    with tempfile.TemporaryDirectory(prefix="prometheus-pre7-image-baseline-") as tmp:
        with tarfile.open(fileobj=io.BytesIO(archive)) as files:
            for member in files.getmembers():
                if member.isfile():
                    target = Path(tmp) / member.name
                    assert Path(tmp).resolve() in target.resolve().parents
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(files.extractfile(member).read())
        original = Path(tmp) / relative
        for extra in ({}, {"thanos": {"enabled": False}},
                      {"thanos": {"spec": {"image": REPOSITORY + ":" + PIN}}},
                      {"thanos": {"components": {"baseImage": "override.example/thanos", "version": "v0.41.0"}}}):
            before = render("image-tags-values.yaml", extra, chart=original)
            after = render("image-tags-values.yaml", extra)
            assert before == after, "ordinary baseline changed"
    print("PASS: actual original-chart baseline (ordinary, disabled, full image, component overrides)")


def probe():
    with tempfile.TemporaryDirectory(prefix="prometheus-pre7-image-probe-") as tmp:
        chart = Path(tmp) / CHART.name
        shutil.copytree(CHART, chart)
        (chart / "templates" / "image-digest-probe.yaml").write_text('''
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-digest-probe
data:
  before: {{ toJson .Values.thanos.spec | quote }}
  resolved: {{ include "prometheus-server-pre7.thanos.spec" . | fromYaml | toJson | quote }}
  after: {{ toJson .Values.thanos.spec | quote }}
''')
        rendered = render(chart=chart)
        data = next(item["data"] for item in rendered
                    if item["metadata"]["name"] == "image-digest-probe")
        assert data["before"] == data["after"], "helper mutated .Values"
        assert json.loads(data["before"])["version"] == PIN
        assert "image" not in json.loads(data["before"])
        assert json.loads(data["resolved"])["version"] == TAG
    print("PASS: spec helper does not mutate .Values")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", help="compare real renders against this original Git revision")
    args = parser.parse_args()
    ordinary = render("image-tags-values.yaml")
    pinned = render()
    assert thanos(pinned)["version"] == TAG
    assert thanos(pinned)["baseImage"] == REPOSITORY
    assert thanos(pinned)["image"] == REPOSITORY + ":" + PIN
    assert set(component_images(pinned).values()) == {REPOSITORY + ":" + PIN}
    comparison = copy.deepcopy(pinned)
    thanos(comparison).pop("image")
    for item in comparison:
        if item["kind"] in ("Deployment", "StatefulSet"):
            for container in item["spec"]["template"]["spec"]["containers"]:
                container["image"] = REPOSITORY + ":" + TAG
    assert comparison == ordinary, "pin changed unrelated manifests or spec fields"
    for image in (REPOSITORY + ":older", REPOSITORY + ":" + PIN,
                  REPOSITORY + "@" + DIGEST):
        assert thanos(render(extra={"thanos": {"spec": {"image": image}}}))["image"] == REPOSITORY + ":" + PIN
    for explicit in (TAG + "@sha256:" + "2" * 64, "v0.39.0@" + DIGEST):
        render(extra={"thanos": {"spec": {"image": REPOSITORY + ":" + explicit}}},
               error="thanos.spec.image pin conflicts")
    rotated = TAG + "@sha256:" + "2" * 64
    rotation = render(extra={"thanos": {"spec": {"version": rotated}}})
    assert thanos(rotation)["version"] == TAG
    assert thanos(rotation)["image"] == REPOSITORY + ":" + rotated
    assert set(component_images(rotation).values()) == {REPOSITORY + ":" + rotated}
    long_tag = TAG + "-" + "a" * 100
    long_render = render(extra={"thanos": {"spec": {"version": long_tag + "@" + DIGEST}}}, release="r" * 53)
    assert thanos(long_render)["version"] == long_tag
    assert set(component_images(long_render).values()) == {REPOSITORY + ":" + long_tag + "@" + DIGEST}
    for components, expected in (
            ({"baseImage": "override.example:5443/thanos", "version": "v0.41.0@" + DIGEST},
             "override.example:5443/thanos:v0.41.0@" + DIGEST),
            ({"baseImage": "override.example/thanos"}, REPOSITORY + ":" + PIN),
            ({"version": "v0.41.0"}, REPOSITORY + ":" + PIN)):
        rendered = render(extra={"thanos": {"components": components}})
        assert thanos(rendered)["image"] == REPOSITORY + ":" + PIN
        assert set(component_images(rendered).values()) == {expected}
    disabled = render(extra={"thanos": {"enabled": False}})
    assert all("thanos" not in item.get("spec", {}) for item in disabled if item["kind"] == "Prometheus")
    assert not any(item["kind"] in ("Deployment", "StatefulSet") for item in disabled)
    render(extra={"thanos": {"spec": {"baseImage": None}}}, error=".Values.thanos.spec.baseImage missing")
    print("PASS: full CR and query/compactor/store, exact pins, ports, fields, matching/conflicting pins, rotation, long tags, overrides, disabled Thanos, labels")
    probe()
    if args.baseline_ref:
        baseline(args.baseline_ref)
    else:
        print("SKIP: original-chart comparison (supply --baseline-ref)")


if __name__ == "__main__":
    main()
