#!/usr/bin/env python3
"""Run from any directory after helm dependency build; requires Helm, yq, git."""
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

CHART = Path(__file__).resolve().parents[1]
ROOT = CHART.parents[1]
BASE = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"
TAG = "v1.2.3"


def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, capture_output=True, **kwargs).stdout


def render(path=CHART, release="digest-test", fixture="image-tags", overrides=None):
    args = ["helm", "template", release, str(path), "-f", str(CHART / "ci" / (fixture + "-values.yaml"))]
    for key, value in (overrides or {}).items():
        args += ["--set-string", key + "=" + value]
    text = run(["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=run(args))
    docs = []
    while text.strip():
        doc, end = json.JSONDecoder().raw_decode(text.lstrip())
        if doc:
            docs.append(doc)
        text = text.lstrip()[end:]
    return docs


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def metadata_labels(docs):
    return {(key, str(value)) for item in walk(docs) for key, value in item.get("metadata", {}).get("labels", {}).items()}


def check(docs, pin, pinned=True, legacy_labels=()):
    name = next(doc["metadata"]["name"] for doc in docs if doc.get("kind") == "Job" and "migration" in doc["metadata"]["name"])
    assert len(name) <= 63 and re.fullmatch(r"[a-z0-9]([-a-z0-9]*[a-z0-9])?", name), name
    if pinned:
        assert re.search(r"-migration-[0-9a-f]{8}$", name), name
    references, images = [], []
    for item in walk(docs):
        for key, value in item.get("metadata", {}).get("labels", {}).items():
            value = str(value)
            assert (key, value) in legacy_labels or (len(value) <= 63 and re.fullmatch(r"([A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?)?", value)), (key, value)
        if item.get("name") == "DEPENDENCY_JOBS":
            references.extend(item.get("value", "").split(","))
        if "/archer:" in str(item.get("image", "")):
            images.append(item["image"])
    assert len(references) == 2 and all(ref == name for ref in references), references
    assert len(images) >= 4 and all(image.endswith(":" + pin) for image in images), images
    return name


def main():
    # Compare actual original templates, with identical chart metadata and real
    # fetched dependencies, rather than only predicting the old Job name.
    with tempfile.TemporaryDirectory(prefix="archer-image-digests-") as temp:
        original = Path(temp) / CHART.name
        shutil.copytree(CHART, original)
        for source in ["_helpers.tpl", "job-migration.yaml", "deployment.yaml", "deployment-f5.yaml"]:
            relative = (CHART / "templates" / source).relative_to(ROOT)
            (original / "templates" / source).write_text(run(["git", "show", BASE + ":" + str(relative)], cwd=ROOT))
        ordinary = render()
        assert ordinary == render(original), "ordinary manifests differ from original templates"
        ordinary_name = check(ordinary, TAG, False)
        pinned = render(fixture="image-digests")
        first = check(pinned, TAG + "@sha256:" + "1" * 64)
        normalized = json.dumps(pinned).replace(TAG + "@sha256:" + "1" * 64, TAG).replace(first, ordinary_name)
        assert json.loads(normalized) == ordinary, "unexpected pinned-manifest changes"
        pin = TAG + "@sha256:" + "2" * 64
        assert first != check(render(overrides={"image.tag": pin}), pin)
        for release, tag in [("r" * 53, TAG), ("digest-test", "V1_" + "X" * 125), ("r" * 53, "V1_" + "X" * 125)]:
            # Long releases already overflow dependency pgmetrics labels; permit
            # only exact original values, never new invalid metadata.
            legacy = metadata_labels(render(original, release=release, overrides={"image.tag": tag}))
            names = []
            for digest in ["1" * 64, "2" * 64]:
                pin = tag + "@sha256:" + digest
                names.append(check(render(release=release, overrides={"image.tag": pin}), pin, legacy_labels=legacy))
            assert names[0] != names[1]
        for key in ["fullnameOverride", "nameOverride"]:
            setting = {key: "custom-name"}
            assert render(overrides=setting) == render(original, overrides=setting)
            check(render(fixture="image-digests", overrides=setting), TAG + "@sha256:" + "1" * 64)
            extreme = {key: "x" * 63}
            legacy = metadata_labels(render(original, overrides=extreme))
            check(render(fixture="image-digests", overrides=extreme), TAG + "@sha256:" + "1" * 64, legacy_labels=legacy)
    print("PASS: original ordinary renders, real dependencies, F5 references, image pins, labels, digest rotation, long metadata and overrides")


if __name__ == "__main__":
    main()
