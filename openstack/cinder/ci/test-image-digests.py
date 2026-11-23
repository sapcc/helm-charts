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
KINDS = ["db-migrate", "db-online-migrate"]


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


def jobs(docs):
    return {kind: next(doc["metadata"]["name"] for doc in docs if doc.get("kind") == "Job" and kind in doc["metadata"]["name"]) for kind in KINDS}


def check(docs, pin, pinned=True, api_pin=None):
    names = jobs(docs)
    for kind, name in names.items():
        assert len(name) <= 63 and re.fullmatch(r"[a-z0-9]([-a-z0-9.]*[a-z0-9])?", name), name
        if pinned:
            assert re.search("-" + kind + r"-[0-9a-f]{4}$", name), name
    images, references = [], []
    for item in walk(docs):
        for key, value in item.get("metadata", {}).get("labels", {}).items():
            value = str(value)
            assert len(value) <= 63 and re.fullmatch(r"([A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?)?", value), (key, value)
        if item.get("name") == "DEPENDENCY_JOBS":
            references.extend(item.get("value", "").split(","))
        if "/loci-cinder:" in str(item.get("image", "")):
            images.append(item["image"])
        # VCenterTemplate consumers are embedded Jinja YAML, not top-level Pods.
        if isinstance(item.get("template"), str):
            text = item["template"]
            references += re.findall(r"name: DEPENDENCY_JOBS\s+value: [\"']?([^\s\"']+)", text)
            images += re.findall(r"image: ([^\s]+/loci-cinder:[^\s]+)", text)
    assert len(references) >= 3 and all(ref in names.values() for ref in references), references
    assert len(images) >= 6 and all(image.endswith(":" + pin) or (api_pin and image.endswith(":" + api_pin)) for image in images), images
    return names


def main():
    # Render original helper source against identical chart metadata/dependencies;
    # compare complete ordinary manifests, not just expected Job-name strings.
    with tempfile.TemporaryDirectory(prefix="cinder-image-digests-") as temp:
        original = Path(temp) / CHART.name
        shutil.copytree(CHART, original)
        source = (CHART / "templates/_helpers.tpl").relative_to(ROOT)
        (original / "templates/_helpers.tpl").write_text(run(["git", "show", BASE + ":" + str(source)], cwd=ROOT))
        for mode in ["", "host_alias", "unix_socket"]:
            setting = {"proxysql.mode": mode}
            ordinary = render(overrides=setting)
            assert ordinary == render(original, overrides=setting), "ordinary manifests differ from original helper"
            ordinary_names = check(ordinary, TAG, False)
            pinned = render(fixture="image-digests", overrides=setting)
            first = check(pinned, TAG + "@sha256:" + "1" * 64)
            normalized = json.dumps(pinned).replace(TAG + "@sha256:" + "1" * 64, TAG)
            for kind in KINDS:
                normalized = normalized.replace(first[kind], ordinary_names[kind])
            assert json.loads(normalized) == ordinary, "unexpected pinned-manifest changes"
            pin = TAG + "@sha256:" + "2" * 64
            second = check(render(overrides={**setting, "imageVersion": pin}), pin)
            assert all(first[kind] != second[kind] for kind in KINDS)
            for release, tag in [("r" * 53, TAG), ("digest-test", "V1_" + "X" * 125), ("r" * 53, "V1_" + "X" * 125)]:
                names = []
                for digest in ["1" * 64, "2" * 64]:
                    pin = tag + "@sha256:" + digest
                    names.append(check(render(release=release, overrides={**setting, "imageVersion": pin}), pin))
                assert all(names[0][kind] != names[1][kind] for kind in KINDS)
            api_pin = "api-override@sha256:" + "3" * 64
            setting["imageVersionCinderApi"] = api_pin
            assert render(overrides=setting) == render(original, overrides=setting)
            check(render(overrides=setting), TAG, False, api_pin)
            check(render(fixture="image-digests", overrides=setting), TAG + "@sha256:" + "1" * 64, api_pin=api_pin)
    print("PASS: original ordinary renders, real dependencies, ProxySQL off/host_alias/unix_socket, both Jobs, all references including VCenterTemplate, pins, labels, long metadata and API override")


if __name__ == "__main__":
    main()
