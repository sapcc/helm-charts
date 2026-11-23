#!/usr/bin/env python3
"""Run from anywhere after `helm dependency build openstack/octavia`.

Requires Helm, Mike Farah yq v4 and Python's standard library. The baseline
restores only the original naming helper in a temporary copy of the real chart;
dependencies and all consumers are rendered unchanged, never stubbed.
"""
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

CHART = Path(__file__).resolve().parents[1]
HELPER = "_helpers.tpl"
NAME = "job_name"
KINDS = ("migration",)
MIN_REFS = 3
OVERRIDES = {"statsd.imageTag": "component@sha256:" + "3" * 64}
OPTIONAL = {"external_as3": True}


def run(args):
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(" ".join(map(str, args)) + "\n" + result.stderr)
    return result.stdout


def yaml_docs(text):
    result = subprocess.run(["yq", "eval-all", "-o=json", "-I=0", ".", "-"],
                            input=text, text=True, capture_output=True, check=True)
    stream, decoder, docs = result.stdout, json.JSONDecoder(), []
    while stream.strip():
        stream = stream.lstrip()
        doc, end = decoder.raw_decode(stream)
        stream = stream[end:]
        if doc is not None:
            docs.append(doc)
    return docs


def render(chart, release, pin, mode, extra=None):
    args = ["helm", "template", release, str(chart),
            "-f", str(CHART / "ci/test-values.yaml"),
            "-f", str(CHART / "ci/image-digests-values.yaml")]
    for key, value in {"imageVersion": pin, "proxysql.mode": mode,
                       **(extra or {})}.items():
        if isinstance(value, bool):
            args += ["--set", key + "=" + str(value).lower()]
        else:
            args += ["--set-string", key + "=" + value]
    return yaml_docs(run(args))


def walk(value):
    yield value
    if isinstance(value, dict):
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def jobs(docs, release, pinned):
    found = {}
    for doc in docs:
        if doc.get("kind") != "Job":
            continue
        name = doc["metadata"]["name"]
        for kind in KINDS:
            if (re.search("-" + kind + "-[0-9a-f]{4}$", name) if pinned
                    else name.startswith(release + "-" + kind + "-")):
                assert kind not in found, (kind, name)
                found[kind] = doc
    assert set(found) == set(KINDS), found
    return found


def check(docs, release, pin, extra_pins=()):
    found = jobs(docs, release, True)
    names = {kind: doc["metadata"]["name"] for kind, doc in found.items()}
    for kind, doc in found.items():
        name = names[kind]
        assert len(name) <= 63 and re.fullmatch("[a-z0-9]([-a-z0-9]*[a-z0-9])?", name), name
        images = [v["image"] for v in walk(doc) if isinstance(v, dict) and "image" in v]
        assert any(image.endswith(":" + pin) for image in images), images
    refs = [ref for v in walk(docs) if isinstance(v, dict)
            and v.get("name") == "DEPENDENCY_JOBS" for ref in v["value"].split(",")]
    assert len(refs) >= MIN_REFS and set(refs) <= set(names.values()), refs
    for value in walk(docs):
        if isinstance(value, dict) and isinstance(value.get("metadata"), dict):
            for label in value["metadata"].get("labels", {}).values():
                label = "" if label is None else str(label)
                assert len(label) <= 63 and re.fullmatch(
                    "([A-Za-z0-9]([A-Za-z0-9_.-]*[A-Za-z0-9])?)?", label), label
    for expected in extra_pins:
        assert any(isinstance(v, dict) and str(v.get("image", "")).endswith(":" + expected)
                   for v in walk(docs)), expected
    return names


def replace(value, substitutions):
    if isinstance(value, dict):
        return {k: replace(v, substitutions) for k, v in value.items()}
    if isinstance(value, list):
        return [replace(v, substitutions) for v in value]
    if isinstance(value, str):
        for old, new in substitutions.items():
            value = value.replace(old, new)
    return value


def main():
    pin = yaml_docs((CHART / "ci/image-digests-values.yaml").read_text())[0]["imageVersion"]
    tag = pin.split("@")[0]
    long_release, long_tag = "release-" + "r" * 45, "V1.2.3_" + "Long_Build." * 10
    with tempfile.TemporaryDirectory(prefix=CHART.name + "-image-digests-") as tmp:
        original = Path(tmp) / CHART.name
        shutil.copytree(CHART, original)
        helper = original / "templates" / HELPER
        text = helper.read_text()
        start = text.index('{{- define "' + NAME + '"')
        end = text.find("{{- define ", start + 10)
        if end < 0:
            end = len(text)
        helper.write_text(text[:start] + (CHART / "ci/original-job-name.tpl").read_text() + text[end:])
        host_names = {}
        for mode in ("", "host_alias", "unix_socket"):
            ordinary = render(CHART, "digest-test", tag, mode)
            assert ordinary == render(original, "digest-test", tag, mode), "ordinary baseline: " + mode
            old_names = {k: d["metadata"]["name"] for k, d in jobs(ordinary, "digest-test", False).items()}
            for name in old_names.values():
                assert len(name) <= 63 and re.fullmatch("[a-z0-9]([-a-z0-9]*[a-z0-9])?", name), name
            boundary_release = "r" * (63 - len(max(KINDS, key=len)) - len(tag) - 7)
            boundary = render(CHART, boundary_release, tag, mode)
            assert boundary == render(original, boundary_release, tag, mode), "63-character ordinary baseline"
            assert max(len(d["metadata"]["name"]) for d in jobs(boundary, boundary_release, False).values()) == 63
            pinned = render(CHART, "digest-test", pin, mode)
            names = check(pinned, "digest-test", pin)
            if mode == "host_alias":
                host_names = names
            substitutions = {pin: tag, **{names[k]: old_names[k] for k in KINDS}}
            assert replace(pinned, substitutions) == ordinary, "unexpected pinned manifest changes: " + mode
            rotated_pin = tag + "@sha256:" + "2" * 64
            rotated = check(render(CHART, "digest-test", rotated_pin, mode), "digest-test", rotated_pin)
            assert all(names[k] != rotated[k] for k in KINDS), "digest rotation: " + mode
            for release, readable in ((long_release, tag), ("digest-test", long_tag), (long_release, long_tag)):
                first, second = readable + "@sha256:" + "1" * 64, readable + "@sha256:" + "2" * 64
                a = check(render(CHART, release, first, mode), release, first)
                b = check(render(CHART, release, second, mode), release, second)
                assert all(a[k] != b[k] for k in KINDS), "long-name digest rotation"
            print("PASS original ordinary baseline, pinned manifest comparison, rotation, long names: " + repr(mode))
        overridden = render(CHART, "digest-test", pin, "host_alias", OVERRIDES)
        assert check(overridden, "digest-test", pin, OVERRIDES.values()) == host_names
        for extra in (OPTIONAL, {"proxysql.native_sidecar": False}):
            assert render(CHART, "digest-test", tag, "host_alias", extra) == render(
                original, "digest-test", tag, "host_alias", extra), "optional ordinary baseline"
            check(render(CHART, "digest-test", pin, "host_alias", extra), "digest-test", pin)
    print("PASS real dependencies, all Job references, image pins, metadata labels, overrides and optional paths")


if __name__ == "__main__":
    main()
