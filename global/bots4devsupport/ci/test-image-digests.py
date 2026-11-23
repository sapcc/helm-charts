#!/usr/bin/env python3
"""Full-chart regression checks. Requires Helm, Mike Farah yq v4 and built deps."""

import copy
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile


CHART = Path(__file__).resolve().parents[1]
ROOT = Path(subprocess.check_output(
    ["git", "-C", str(CHART), "rev-parse", "--show-toplevel"], text=True).strip())
BASE = os.environ.get("IMAGE_DIGEST_BASE_REF", "04f4dbf7da48feb93e052fe1e2597f8415cae1e1")
VERSION = "app.kubernetes.io/version"
PIN = "@sha256:" + "1" * 64
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?)?")


def documents(yaml):
    stream = subprocess.check_output(
        ["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=yaml, text=True)
    decoder = json.JSONDecoder()
    result = []
    while stream.strip():
        value, end = decoder.raw_decode(stream.lstrip())
        if value is not None:
            result.append(value)
        stream = stream.lstrip()[end:]
    return result


def render(chart, fixture="image-tag-values.yaml", tag=None):
    args = ["helm", "template", "digest-regression", str(chart),
            "-f", str(CHART / "ci" / fixture)]
    if tag is not None:
        args += ["--set-string", "imageTag=" + tag]
    return documents(subprocess.check_output(args, text=True))


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def check(manifests, tag, expected):
    versions = []
    for node in walk(manifests):
        for key, value in node.get("labels", {}).items():
            assert isinstance(value, str) and LABEL.fullmatch(value), (key, value)
            if key == VERSION:
                versions.append(value)
    assert versions == [expected, expected], versions
    deployment, = [m for m in manifests if m["kind"] == "Deployment"]
    assert deployment["metadata"]["labels"][VERSION] == expected
    assert deployment["spec"]["template"]["metadata"]["labels"][VERSION] == expected
    container, = deployment["spec"]["template"]["spec"]["containers"]
    assert container["image"] == "registry.example.com/" + CHART.name + ":" + tag


def without_images(manifests):
    result = copy.deepcopy(manifests)
    for node in walk(result):
        if "image" in node:
            node["image"] = "<image>"
    return result


def main():
    with tempfile.TemporaryDirectory(prefix="image-digest-baseline-") as temp:
        archive = subprocess.check_output(
            ["git", "-C", str(ROOT), "archive", BASE, str(CHART.relative_to(ROOT))])
        with tarfile.open(fileobj=io.BytesIO(archive)) as source:
            for member in source.getmembers():
                path = Path(member.name)
                assert not path.is_absolute() and ".." not in path.parts
                target = Path(temp) / path
                if member.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    assert member.isfile(), member.name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(source.extractfile(member).read())
        baseline = Path(temp) / CHART.relative_to(ROOT)
        # Only align the release version; original templates and defaults stay untouched.
        # This also avoids checksum differences caused solely by helm.sh/chart labels.
        metadata, = documents((baseline / "Chart.yaml").read_text())
        current_metadata, = documents((CHART / "Chart.yaml").read_text())
        metadata["version"] = current_metadata["version"]
        (baseline / "Chart.yaml").write_text(json.dumps(metadata))
        shutil.copytree(CHART / "charts", baseline / "charts")
        ordinary = render(CHART)
        assert ordinary == render(baseline), "ordinary manifests differ from original"
        check(ordinary, "v1.2.3", "v1.2.3")
        for tag in ["SET-IN-PIPELINE", "Release_1.2-3", "a" * 63]:
            current = render(CHART, tag=tag)
            check(current, tag, tag)
            assert current == render(baseline, tag=tag), tag

    pinned = render(CHART, "image-digest-values.yaml")
    check(pinned, "v1.2.3" + PIN, "v1.2.3")
    assert without_images(ordinary) == without_images(pinned)
    rotated = render(CHART, tag="v1.2.3@sha256:" + "2" * 64)
    check(rotated, "v1.2.3@sha256:" + "2" * 64, "v1.2.3")
    assert without_images(pinned) == without_images(rotated)
    for tag, expected in [
        ("a" * 100, "a" * 63),
        ("a" * 62 + "_tail", "a" * 62),
        ("_v1.2.3_", "v1.2.3"),
        ("_.-Release_1.2-3-._", "Release_1.2-3"),
        ("v1+build:bad", "v1_build_bad"),
        ("___", ""),
    ]:
        for pin in [tag, tag + PIN]:
            check(render(CHART, tag=pin), pin, expected)
    print("PASS: full manifests, original ordinary baseline, metadata/Pod labels, "
          "pins, digest rotation and long/invalid labels")


if __name__ == "__main__":
    main()
