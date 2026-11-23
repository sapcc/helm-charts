#!/usr/bin/env python3
"""Run from any directory; requires helm dependency build, Helm, yq and git."""
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

CHART = Path(__file__).resolve().parents[1]
ROOT = CHART.parents[1]
BASE = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"
VALUE = "image.tag"
TAG = "v1.2.3"
IMAGE = "/andromeda:"
KINDS = ["migration"]
SOURCES = ["templates/_helpers.tpl", "templates/job-migration.yaml", "templates/deployment.yaml"]
PROXY_MODES = [None]
MIN_REFERENCES = 1


def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, capture_output=True, **kwargs).stdout


def objects(text):
    text = run(["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=text)
    decoder = json.JSONDecoder()
    result = []
    while text.strip():
        item, end = decoder.raw_decode(text.lstrip())
        if item:
            result.append(item)
        text = text.lstrip()[end:]
    return result


def render(path=CHART, release="digest-test", fixture="image-tags", overrides=None):
    args = ["helm", "template", release, str(path), "-f", str(CHART / "ci" / (fixture + "-values.yaml"))]
    for key, value in (overrides or {}).items():
        args.extend(["--set-string", key + "=" + value])
    return objects(run(args))


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def jobs(docs):
    return {kind: next(doc["metadata"]["name"] for doc in docs if doc.get("kind") == "Job"
                       and kind in doc["metadata"]["name"]) for kind in KINDS}


def metadata_labels(docs):
    return {(key, str(value)) for item in walk(docs) for key, value in item.get("metadata", {}).get("labels", {}).items()}


def check(docs, pin, pinned=True, legacy_labels=()):
    names = jobs(docs)
    for kind, name in names.items():
        assert len(name) <= 63 and re.fullmatch(r"[a-z0-9]([-a-z0-9.]*[a-z0-9])?", name), name
        if pinned:
            assert re.search("-" + kind + r"-[0-9a-f]{8}$", name), name
    references = []
    images = []
    for item in walk(docs):
        # Alert-rule labels are not Kubernetes metadata labels. Only exact
        # original-label values may bypass validation in extreme metadata cases.
        for key, value in item.get("metadata", {}).get("labels", {}).items():
            value = str(value)
            assert (key, value) in legacy_labels or (len(value) <= 63 and re.fullmatch(r"([A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?)?", value)), (key, value)
        if item.get("name") == "DEPENDENCY_JOBS":
            references.extend(item.get("value", "").split(","))
        if IMAGE in str(item.get("image", "")):
            images.append(item["image"])
    assert len(references) >= MIN_REFERENCES, references
    assert all(ref in names.values() for ref in references), references
    assert images and all(image.endswith(":" + pin) for image in images), images
    return names


def main():
    # Restore the actual original naming templates, retaining identical chart
    # metadata and real dependencies to isolate template behavior in the diff.
    with tempfile.TemporaryDirectory(prefix="andromeda-image-digests-") as temp:
        original = Path(temp) / CHART.name
        shutil.copytree(CHART, original)
        for source in SOURCES:
            relative = (CHART / source).relative_to(ROOT)
            (original / source).write_text(run(["git", "show", BASE + ":" + str(relative)], cwd=ROOT))
        for mode in PROXY_MODES:
            overrides = {} if mode is None else {"proxysql.mode": mode}
            ordinary = render(overrides=overrides)
            assert ordinary == render(original, overrides=overrides), "ordinary manifests differ from original templates"
            ordinary_names = check(ordinary, TAG, False)
            pinned = render(fixture="image-digests", overrides=overrides)
            first = check(pinned, TAG + "@sha256:" + "1" * 64)
            normalized = json.dumps(pinned).replace(TAG + "@sha256:" + "1" * 64, TAG)
            for kind in KINDS:
                normalized = normalized.replace(first[kind], ordinary_names[kind])
            assert json.loads(normalized) == ordinary, "unexpected pinned-manifest changes"
            second_pin = TAG + "@sha256:" + "2" * 64
            second = check(render(overrides={**overrides, VALUE: second_pin}), second_pin)
            assert all(first[kind] != second[kind] for kind in KINDS), (first, second)
            for release, tag in [("r" * 53, TAG), ("digest-test", "V1_" + "X" * 125), ("r" * 53, "V1_" + "X" * 125)]:
                legacy = metadata_labels(render(original, release=release, overrides={**overrides, VALUE: tag}))
                pin = tag + "@sha256:" + "1" * 64
                long_first = check(render(release=release, overrides={**overrides, VALUE: pin}), pin, legacy_labels=legacy)
                pin = tag + "@sha256:" + "2" * 64
                long_second = check(render(release=release, overrides={**overrides, VALUE: pin}), pin, legacy_labels=legacy)
                assert all(long_first[kind] != long_second[kind] for kind in KINDS)
            for key in ["fullnameOverride", "nameOverride"]:
                setting = {**overrides, key: "custom-name"}
                assert render(overrides=setting) == render(original, overrides=setting)
                check(render(fixture="image-digests", overrides=setting), TAG + "@sha256:" + "1" * 64)
                extreme = {**setting, key: "x" * 63}
                legacy = metadata_labels(render(original, overrides=extreme))
                check(render(fixture="image-digests", overrides=extreme), TAG + "@sha256:" + "1" * 64, legacy_labels=legacy)
    print("PASS: original ordinary renders, real dependencies, image pins, labels, references, digest rotation, long metadata and overrides")


if __name__ == "__main__":
    main()
