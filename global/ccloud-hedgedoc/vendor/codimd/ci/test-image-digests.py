#!/usr/bin/env python3
"""Check real standalone CodiMD and parent renders, including original baselines."""

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
PARENT = CHART.parents[1]
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


def render(chart, fixture="image-tag-values.yaml", tag=None, settings=()):
    values, = documents((CHART / "ci" / fixture).read_text())
    parent = chart.name == PARENT.name
    args = ["helm", "template", "digest-regression", str(chart)]
    if parent:
        args += ["-f", str(PARENT / "ci" / "test-values.yaml")]
        values = {"codimd": values, "global": {"linkerd_enabled": False}}
    prefix = "codimd." if parent else ""
    if tag is not None:
        args += ["--set-string", prefix + "image.tag=" + tag]
    for key, value in settings:
        args += ["--set-string", prefix + key + "=" + value]
    with tempfile.TemporaryDirectory(prefix="codimd-values-") as temp:
        fixture_path = Path(temp) / "values.json"
        fixture_path.write_text(json.dumps(values))
        args += ["-f", str(fixture_path)]
        return documents(subprocess.check_output(args, text=True))


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def check(manifests, tag, expected, repository="registry.example.com/hedgedoc/hedgedoc"):
    versions = []
    for node in walk(manifests):
        # Alert-rule labels are not Kubernetes metadata and may contain URLs.
        labels = node.get("metadata", {}).get("labels", {})
        for key, value in labels.items():
            assert isinstance(value, str) and LABEL.fullmatch(value), (key, value)
        if labels.get("app.kubernetes.io/name") == "codimd":
            assert labels[VERSION] == expected, labels
            versions.append(labels[VERSION])
    assert len(versions) >= 3, versions
    deployment, = [m for m in manifests if m["kind"] == "Deployment"
                   and m["metadata"].get("labels", {}).get("app.kubernetes.io/name") == "codimd"]
    assert deployment["metadata"]["labels"][VERSION] == expected
    assert deployment["spec"]["template"]["metadata"]["labels"][VERSION] == expected
    container, = deployment["spec"]["template"]["spec"]["containers"]
    assert container["image"] == repository + ":" + tag, container["image"]
    service, = [m for m in manifests if m["kind"] == "Service"
                and m["metadata"].get("labels", {}).get("app.kubernetes.io/name") == "codimd"]
    assert service["spec"]["selector"][VERSION] == expected


def without_codimd_image(manifests):
    result = copy.deepcopy(manifests)
    for node in walk(result):
        if node.get("name") == "codimd" and "image" in node:
            node["image"] = "<codimd-image>"
    return result


def suite(chart, baseline):
    ordinary = render(chart)
    check(ordinary, "v1.2.3", "v1.2.3")
    assert ordinary == render(baseline), "ordinary manifests differ from original"
    kinds = {m["kind"] for m in ordinary
             if m["metadata"].get("labels", {}).get("app.kubernetes.io/name") == "codimd"}
    assert {"Deployment", "Service", "Ingress", "PersistentVolumeClaim", "Secret"} <= kinds
    for tag in ["1.9.3-debian", "Release_1.2-3", "a" * 63, ""]:
        current = render(chart, tag=tag)
        check(current, tag or "1.9.3", tag or "1.9.3")
        assert current == render(baseline, tag=tag), tag

    pinned = render(chart, "image-digest-values.yaml")
    check(pinned, "v1.2.3" + PIN, "v1.2.3")
    assert without_codimd_image(ordinary) == without_codimd_image(pinned)
    rotated = render(chart, tag="v1.2.3@sha256:" + "2" * 64)
    check(rotated, "v1.2.3@sha256:" + "2" * 64, "v1.2.3")
    assert without_codimd_image(pinned) == without_codimd_image(rotated)
    for tag, expected in [
        ("a" * 100, "a" * 63),
        ("a" * 62 + "_tail", "a" * 62),
        ("_v1.2.3_", "v1.2.3"),
        ("_.-Release_1.2-3-._", "Release_1.2-3"),
        ("v1+build:bad", "v1_build_bad"),
        ("___", ""),
    ]:
        for pin in [tag, tag + PIN]:
            check(render(chart, tag=pin), pin, expected)

    # Exercise the shared version label on the optional image-upload Secret.
    uploaded = render(chart, "image-upload-digest-values.yaml", tag="v1.2.3")
    assert uploaded == render(baseline, "image-upload-digest-values.yaml", tag="v1.2.3")
    uploaded_pin = render(chart, "image-upload-digest-values.yaml")
    check(uploaded_pin, "v1.2.3" + PIN, "v1.2.3")
    assert any(m["metadata"]["name"].endswith("-image-upload") for m in uploaded_pin)
    assert without_codimd_image(uploaded) == without_codimd_image(uploaded_pin)
    # Use JSON booleans, rather than truthy --set-string values.
    disabled_ordinary = render_disabled(chart)
    check(disabled_ordinary, "v1.2.3", "v1.2.3")
    assert disabled_ordinary == render_disabled(baseline)
    disabled_pin = render_disabled(chart, "v1.2.3" + PIN)
    check(disabled_pin, "v1.2.3" + PIN, "v1.2.3")
    assert not any(m["kind"] in {"Ingress", "PersistentVolumeClaim", "Secret"}
                   and m["metadata"].get("labels", {}).get("app.kubernetes.io/name") == "codimd"
                   for m in disabled_pin)
    assert without_codimd_image(disabled_ordinary) == without_codimd_image(disabled_pin)
    defaults = [("image.registry", ""), ("image.repository", "")]
    image_defaults = render(chart, tag="v1.2.3" + PIN, settings=defaults)
    check(image_defaults, "v1.2.3" + PIN, "v1.2.3", "nabo.codimd.dev/hackmdio/hackmd")
    print("PASS: " + chart.name
          + " full manifests, original baseline, pins, all version labels, "
          "long/invalid labels, fallback and optional resources")


def render_disabled(chart, tag="v1.2.3"):
    # Use JSON booleans in a temporary fixture instead of changing checked-in values.
    values, = documents((CHART / "ci" / "image-tag-values.yaml").read_text())
    values["ingress"]["enabled"] = False
    values["codimd"]["imageStorePersistentVolume"] = {"enabled": False}
    values["codimd"]["security"]["sessionSecret"] = ""
    values["image"]["tag"] = tag
    parent = chart.name == PARENT.name
    args = ["helm", "template", "digest-regression", str(chart)]
    if parent:
        args += ["-f", str(PARENT / "ci" / "test-values.yaml")]
        values = {"codimd": values, "global": {"linkerd_enabled": False}}
    with tempfile.TemporaryDirectory(prefix="codimd-values-") as temp:
        fixture = Path(temp) / "values.json"
        fixture.write_text(json.dumps(values))
        args += ["-f", str(fixture)]
        return documents(subprocess.check_output(args, text=True))


def main():
    with tempfile.TemporaryDirectory(prefix="codimd-baseline-") as temp:
        archive = subprocess.check_output(
            ["git", "-C", str(ROOT), "archive", BASE, str(PARENT.relative_to(ROOT))])
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
        baseline_parent = Path(temp) / PARENT.relative_to(ROOT)
        original_lock, = documents((baseline_parent / "Chart.lock").read_text())
        current_lock, = documents((PARENT / "Chart.lock").read_text())
        assert current_lock["dependencies"][1:] == original_lock["dependencies"][1:]
        assert current_lock["dependencies"][0] == {
            **original_lock["dependencies"][0], "version": "0.1.12"}
        baseline = baseline_parent / "vendor" / "codimd"
        # Align only the vendored release version, preserving all original templates.
        metadata, = documents((baseline / "Chart.yaml").read_text())
        current_metadata, = documents((CHART / "Chart.yaml").read_text())
        metadata["version"] = current_metadata["version"]
        (baseline / "Chart.yaml").write_text(json.dumps(metadata))
        suite(CHART, baseline)
        # Keep genuine external dependencies, but load ORIGINAL CodiMD source in the
        # baseline parent instead of the modified vendored package.
        deps = baseline_parent / "charts"
        deps.mkdir()
        for dependency in (PARENT / "charts").iterdir():
            if not dependency.name.startswith("codimd"):
                if dependency.is_dir():
                    shutil.copytree(dependency, deps / dependency.name)
                else:
                    shutil.copy2(dependency, deps / dependency.name)
        shutil.copytree(baseline, deps / "codimd")
        suite(PARENT, baseline_parent)


if __name__ == "__main__":
    main()
