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
TAG = "yoga"


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
    name = next(doc["metadata"]["name"] for doc in docs if doc.get("kind") == "Job" and "migration-job" in doc["metadata"]["name"])
    assert len(name) <= 63 and re.fullmatch(r"[a-z0-9]([-a-z0-9.]*[a-z0-9])?", name), name
    if pinned:
        assert re.search(r"-migration-job-[0-9a-f]{4}$", name), name
    images = []
    for item in walk(docs):
        for key, value in item.get("metadata", {}).get("labels", {}).items():
            value = str(value)
            assert (key, value) in legacy_labels or (len(value) <= 63 and re.fullmatch(r"([A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?)?", value)), (key, value)
        if item.get("name") == "DEPENDENCY_JOBS":
            assert all(ref == name for ref in item.get("value", "").split(",")), item
        if "/loci-barbican:" in str(item.get("image", "")):
            images.append(item["image"])
    assert len(images) >= 3 and all(image.endswith(":" + pin) for image in images), images
    return name


def main():
    # Use the original helper with real dependencies and identical Chart metadata
    # for a full ordinary-manifest comparison in both ProxySQL branches.
    with tempfile.TemporaryDirectory(prefix="barbican-image-digests-") as temp:
        original = Path(temp) / CHART.name
        shutil.copytree(CHART, original)
        source = (CHART / "templates/_helpers.tpl").relative_to(ROOT)
        (original / "templates/_helpers.tpl").write_text(run(["git", "show", BASE + ":" + str(source)], cwd=ROOT))
        for mode in ["", "host_alias", "unix_socket"]:
            setting = {"proxysql.mode": mode}
            ordinary = render(overrides=setting)
            assert ordinary == render(original, overrides=setting), "ordinary manifests differ from original helper"
            ordinary_name = check(ordinary, TAG, False)
            pinned = render(fixture="image-digests", overrides=setting)
            first = check(pinned, TAG + "@sha256:" + "1" * 64)
            normalized = json.dumps(pinned).replace(TAG + "@sha256:" + "1" * 64, TAG).replace(first, ordinary_name)
            assert json.loads(normalized) == ordinary, "unexpected pinned-manifest changes"
            pin = TAG + "@sha256:" + "2" * 64
            assert first != check(render(overrides={**setting, "imageVersionBarbicanApi": pin}), pin)
            for release, tag in [("r" * 53, TAG), ("digest-test", "V1_" + "X" * 125), ("r" * 53, "V1_" + "X" * 125)]:
                # Redis dependency labels already exceed 63 at long releases;
                # permit only exact original values, never new invalid labels.
                legacy = metadata_labels(render(original, release=release, overrides={**setting, "imageVersionBarbicanApi": tag}))
                names = []
                for digest in ["1" * 64, "2" * 64]:
                    pin = tag + "@sha256:" + digest
                    names.append(check(render(release=release, overrides={**setting, "imageVersionBarbicanApi": pin}), pin, legacy_labels=legacy))
                assert names[0] != names[1]
        failed = subprocess.run(["helm", "template", "digest-test", str(CHART), "-f", str(CHART / "ci/image-tags-values.yaml"), "--set-string", "imageVersionBarbicanApi="], text=True, capture_output=True)
        assert failed.returncode and "imageVersionBarbicanApi" in failed.stderr, failed.stderr
    print("PASS: original ordinary renders, real dependencies, ProxySQL off/host_alias/unix_socket, nanny pins, labels, digest rotation, long metadata and required value")


if __name__ == "__main__":
    main()
