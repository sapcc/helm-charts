#!/usr/bin/env python3
"""Run from any directory after `helm dependency build openstack/designate`.

Requires Helm, Mike Farah yq, Python's standard library and the Git base commit.
The baseline uses the original helper with real dependencies in a chart copy;
the current Chart.yaml deliberately excludes the unrelated version bump.
"""
import copy
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

CHART = Path(__file__).resolve().parents[1]
ROOT = CHART.parents[1]
BASE = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"
KEY = "image_version_designate"
TAG = "v1"
KINDS = ("migration",)
REF_COUNT = 3
PIN = TAG + "@sha256:" + "1" * 64
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]*[A-Za-z0-9])?)?")


def run(command, **kwargs):
    result = subprocess.run(command, text=True, capture_output=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"{' '.join(map(str, command))}\n{result.stderr}")
    return result.stdout


def parse(text):
    stream = run(["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=text)
    documents, decoder = [], json.JSONDecoder()
    while stream.strip():
        value, end = decoder.raw_decode(stream.lstrip())
        stream = stream.lstrip()[end:]
        if value:
            documents.append(value)
    return documents


def render(chart=CHART, fixture="image-tags-values.yaml", release="test", sets=()):
    command = ["helm", "template", release, str(chart), "-f", str(CHART / "ci" / fixture)]
    for value in sets:
        command += ["--set" if value.rsplit("=", 1)[-1] in ("true", "false") else "--set-string", value]
    return parse(run(command))


def walk(value):
    yield value
    if isinstance(value, dict):
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def jobs(documents):
    return sorted(d["metadata"]["name"] for d in documents
                  if d.get("kind") == "Job" and "-migration-" in d["metadata"]["name"])


def check(documents, pin, bounded=True):
    names = jobs(documents)
    assert len(names) == len(KINDS), names
    if bounded:
        for name in names:
            assert len(name) <= 63 and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name), name
    if "@" in pin:
        for kind in KINDS:
            assert any(re.search(rf"-{kind}-[0-9a-f]{{4}}$", n) for n in names), names
    refs, images = [], []
    for value in walk(documents):
        if not isinstance(value, dict):
            continue
        if value.get("name") == "DEPENDENCY_JOBS" and value.get("value"):
            refs.extend(value["value"].split(","))
        image = value.get("image", "")
        if isinstance(image, str) and f"/loci-{CHART.name}:" in image:
            images.append(image)
        # Validate every label, including dependency resources and Pod templates.
        for label in (value.get("metadata", {}).get("labels") or {}).values():
            assert isinstance(label, str) and len(label) <= 63 and LABEL.fullmatch(label), label
    migration_refs = [ref for ref in refs if "migration" in ref]
    assert len(migration_refs) == REF_COUNT, migration_refs
    assert all(ref in names for ref in migration_refs), (migration_refs, names)
    assert images and all(image.endswith(":" + pin) for image in images), images
    return names


def normalize(value, replacements):
    if isinstance(value, str):
        for old, new in replacements:
            value = value.replace(old, new)
    elif isinstance(value, dict):
        value = {k: normalize(v, replacements) for k, v in value.items()}
    elif isinstance(value, list):
        value = [normalize(v, replacements) for v in value]
    return value


def main():
    with tempfile.TemporaryDirectory(prefix="designate-image-digests-") as directory:
        baseline = Path(directory) / CHART.name
        shutil.copytree(CHART, baseline)
        original = run(["git", "show", f"{BASE}:openstack/{CHART.name}/templates/_helpers.tpl"], cwd=ROOT)
        (baseline / "templates/_helpers.tpl").write_text(original)
        for mode, native in (("", "true"), ("host_alias", "true"), ("unix_socket", "true"), ("unix_socket", "false")):
            settings = (f"proxysql.mode={mode}", f"proxysql.native_sidecar={native}")
            ordinary = render(sets=settings)
            assert ordinary == render(chart=baseline, sets=settings), (mode, "original baseline differs")
            for release, tag in (("test", "v" + "x" * 32), ("r" * 20, TAG)):
                case = settings + (f"{KEY}={tag}",)
                output = render(release=release, sets=case)
                assert output == render(chart=baseline, release=release, sets=case), "ordinary metadata baseline differs"
                check(output, tag)
            old_names = check(ordinary, TAG)
            pinned = render(fixture="image-digests-values.yaml", sets=settings)
            new_names = check(pinned, PIN)
            assert not set(old_names) & set(new_names)
            replacements = list(zip(new_names, old_names)) + [(PIN, TAG)]
            assert normalize(copy.deepcopy(pinned), replacements) == ordinary, (mode, "unexpected manifest changes")
            rotated_pin = TAG + "@sha256:" + "2" * 64
            rotated = render(sets=settings + (f"{KEY}={rotated_pin}",))
            assert not set(new_names) & set(check(rotated, rotated_pin)), mode
            for release, tag in (("test", "V1_2.3"), ("r" * 53, "v" + "x" * 120)):
                pin = tag + "@sha256:" + "1" * 64
                long_names = check(render(release=release, sets=settings + (f"{KEY}={pin}",)), pin)
                changed_pin = tag + "@sha256:" + "2" * 64
                changed = check(render(release=release, sets=settings + (f"{KEY}={changed_pin}",)), changed_pin)
                assert not set(long_names) & set(changed)
            print(f"PASS: original baseline, pins, rotation, dependency references, labels and long metadata; ProxySQL={mode!r}, native={native}")
        alias = ("dbType=pxc-db", "pxc_db.enabled=true", "mariadb.enabled=false", "proxysql.mode=host_alias",
                 "pxc_db.users.designate.password=test-password")
        alias += tuple(f"pxc_db.system_users.{user}.password=test-password" for user in
                       ("root", "xtrabackup", "monitor", "proxyadmin", "operator", "replication"))
        ordinary = render(sets=alias)
        assert ordinary == render(chart=baseline, sets=alias)
        check(ordinary, TAG)
        pinned = render(fixture="image-digests-values.yaml", sets=alias)
        check(pinned, PIN)
        assert any(d.get("kind") == "PerconaXtraDBCluster" for d in pinned), "pxc_db alias was not rendered"
        print("PASS: integrated pxc_db dependency alias and original baseline")
        # Existing required-value handling must still reject an empty image version.
        try:
            render(sets=(f"{KEY}=",))
        except RuntimeError as error:
            assert "image_version_designate is missing" in str(error)
        else:
            raise AssertionError("missing image version was accepted")
    print("PASS: designate image digest regression suite")


if __name__ == "__main__":
    main()
