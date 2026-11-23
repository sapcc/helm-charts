#!/usr/bin/env python3
"""Full-chart regressions; requires Helm, Mike Farah yq and Python's standard library.

Run from the repository root: common/mariadb-galera/helm/tests/image-digests.py
Run from the chart directory: tests/image-digests.py
The original chart is read from BASELINE_REF without modifying the checkout.
For a shallow checkout, fetch that commit or pass --baseline-chart /path/to/original.
"""

import argparse
import copy
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile


CHART = Path(__file__).resolve().parents[1]
CHART_PATH = "common/mariadb-galera/helm"
BASELINE_REF = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"
DIGEST = "sha256:" + "1" * 64
ROTATED = "sha256:" + "2" * 64
BUILD = "20240724035543"
COMPONENTS = {
    "database": ("mariadb-galera", "10.5.25"),
    "os": ("mariadb-galera-ubuntu", "22.04"),
    "monitoring": ("mariadb-galera-mysqld_exporter", "0.14.0"),
    "proxysql": ("mariadb-galera-proxysql", "2.6.3"),
    "haproxy": ("mariadb-galera-haproxy", "2.8.10"),
    "kopiabackup": ("mariadb-galera-kopia", "0.17.0"),
}
SITES = {
    "statefulset-mariadb.yaml", "statefulset-proxysql.yaml",
    "deployment-haproxy.yaml", "deployment-kopia-server.yaml",
    "cronjob-kopia-backup.yaml", "job-kopia-restore.yaml",
    "job-mariadb-config.yaml",
}
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[A-Za-z0-9_.-]{0,61}[A-Za-z0-9])?)?")
DNS = re.compile(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?")
SOURCES = set()
RENDERS = 0


def command(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True, **kwargs)


def decode_yaml(text):
    result = command(["yq", "eval-all", "-o=json", "-I=0", ".", "-"], input=text)
    assert result.returncode == 0, result.stderr
    decoder = json.JSONDecoder()
    rest = result.stdout.lstrip()
    docs = []
    while rest:
        doc, end = decoder.raw_decode(rest)
        if doc is not None:
            docs.append(doc)
        rest = rest[end:].lstrip()
    return docs


def render(chart=CHART, fixture="ordinary", overrides=None, failure=None):
    global RENDERS
    args = ["helm", "template", "testrelease", str(chart), "--namespace", "testnamespace",
            "-f", str(CHART / "ci" / f"image-digests-{fixture}-values.yaml")]
    for key, value in (overrides or {}).items():
        flag = "--set" if value in ("true", "false") else "--set-string"
        args += [flag, f"{key}={value}"]
    result = command(args)
    RENDERS += 1
    if failure:
        assert result.returncode != 0, "conflicting digests unexpectedly rendered"
        assert failure in result.stderr, result.stderr
        return None
    assert result.returncode == 0, result.stderr
    if chart == CHART:
        SOURCES.update(re.findall(r"# Source: mariadb-galera/templates/([^\n]+)", result.stdout))
    return decode_yaml(result.stdout)


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def canonical(docs, strip_pins=False):
    docs = copy.deepcopy(docs)
    for doc in docs:
        if doc["kind"] in ("Job", "CronJob"):
            name = doc["metadata"]["name"]
            doc["metadata"]["name"] = re.sub(r"-[a-z0-9]{8}$", "-RANDOM", name)
        for node in walk(doc):
            if "helm.sh/chart" in node:
                node["helm.sh/chart"] = "mariadb-galera-CHART_VERSION"
            if strip_pins and "image" in node and isinstance(node["image"], str):
                node["image"] = node["image"].split("@", 1)[0]
    return sorted(docs, key=lambda d: (d["kind"], d["metadata"]["name"]))


def assert_equal(actual, expected, description):
    assert actual == expected, description + " (full manifest comparison failed)"


def validate(docs, proxy="proxysql", restore=False, digest=None, software=None):
    software = software or {key: version for key, (_, version) in COMPONENTS.items()}
    expected = {"database", "os", "kopiabackup"}
    if not restore:
        expected.update(("monitoring", proxy))
    seen = set()
    maria_versions = 0
    cronjobs = 0
    for doc in docs:
        if doc["kind"] in ("Job", "CronJob"):
            name = doc["metadata"]["name"]
            assert len(name) <= 63 and DNS.fullmatch(name), name
            if doc["kind"] == "CronJob":
                cronjobs += 1
                assert len(name) <= 52, name
                assert re.search(r"-backup-kopia-(full|binlog)-[a-z0-9]{8}$", name), name
            else:
                assert re.search(r"-(cfg|restore-kopia)-[a-z0-9]{8}$", name), name
        for node in walk(doc):
            for key, value in (node.get("labels") or {}).items():
                assert isinstance(value, str) and LABEL.fullmatch(value), (key, value)
                assert "@" not in value, (key, value)
            if node.get("name") == "MARIADB_VERSION":
                maria_versions += 1
                assert node["value"] == software["database"], node
            if "image" not in node:
                continue
            image = node["image"]
            matches = [key for key, (name, _) in COMPONENTS.items()
                       if image.startswith(f"keppel.eu-de-1.cloud.sap/ccloud/{name}:")]
            assert len(matches) == 1, image
            component = matches[0]
            seen.add(component)
            name = COMPONENTS[component][0]
            wanted = f"keppel.eu-de-1.cloud.sap/ccloud/{name}:{software[component]}-{BUILD}"
            if digest:
                wanted += "@" + digest
            assert image == wanted, (image, wanted)
            assert image.count("@") == (1 if digest else 0), image
    assert seen == expected, (seen, expected)
    assert maria_versions == (1 if restore else 2), maria_versions
    assert cronjobs == (0 if restore else 2), cronjobs
    assert any(doc["kind"] == "Job" and "-cfg-" in doc["metadata"]["name"] for doc in docs) == (not restore)
    assert any(doc["kind"] == "Job" and "-restore-kopia-" in doc["metadata"]["name"]
               for doc in docs) == restore


def pin_overrides(fields, digest=DIGEST, software=None):
    software = software or {key: version for key, (_, version) in COMPONENTS.items()}
    overrides = {}
    for component in COMPONENTS:
        if "software" in fields:
            overrides[f"image.{component}.softwareversion"] = software[component] + "@" + digest
        if "build" in fields:
            overrides[f"image.{component}.imageversion"] = BUILD + "@" + digest
    return overrides


def run(baseline):
    # Numeric defaults and existing unit-test values must match actual original renders.
    result = command(["helm", "template", "testrelease", str(CHART), "-f",
                      str(CHART / "tests/default_values.yaml")])
    original = command(["helm", "template", "testrelease", str(baseline), "-f",
                        str(CHART / "tests/default_values.yaml")])
    assert result.returncode == original.returncode == 0, result.stderr + original.stderr
    assert_equal(canonical(decode_yaml(result.stdout)), canonical(decode_yaml(original.stdout)),
                 "existing ordinary test values versus original")
    for proxy in ("proxysql", "haproxy"):
        for restore in (False, True):
            options = {"proxy.type": proxy, "mariadb.galera.restore.kopia.enabled": str(restore).lower()}
            ordinary = render(overrides=options)
            validate(ordinary, proxy, restore)
            assert_equal(canonical(ordinary), canonical(render(baseline, overrides=options)),
                         f"numeric defaults versus original: {proxy}, restore={restore}")
            for fixture in ("build", "software"):
                pinned = render(fixture=fixture, overrides=options)
                validate(pinned, proxy, restore, DIGEST)
                assert_equal(canonical(pinned, strip_pins=True), canonical(ordinary),
                             f"only images differ: {fixture}, {proxy}, restore={restore}")
            both = render(overrides={**options, **pin_overrides(("software", "build"))})
            validate(both, proxy, restore, DIGEST)
            assert_equal(canonical(both, strip_pins=True), canonical(ordinary), "matching pins")
            rotated = render(overrides={**options, **pin_overrides(("software", "build"), ROTATED)})
            validate(rotated, proxy, restore, ROTATED)
            assert canonical(rotated) != canonical(both), "digest rotation did not change images"
            assert_equal(canonical(rotated, strip_pins=True), canonical(ordinary), "digest rotation metadata")

    # Long valid image tags need bounded labels with alphanumeric endpoints, without shortening images.
    long_tag = "_" + "v" * 61 + "." + "v" * 30
    long_versions = dict.fromkeys(COMPONENTS, long_tag)
    for proxy in ("proxysql", "haproxy"):
        for restore in (False, True):
            options = {"proxy.type": proxy, "mariadb.galera.restore.kopia.enabled": str(restore).lower()}
            docs = render(overrides={**options, **pin_overrides(("software",), software=long_versions)})
            validate(docs, proxy, restore, DIGEST, long_versions)
            labels = [node["labels"]["app.kubernetes.io/version"] for doc in docs for node in walk(doc)
                      if "app.kubernetes.io/version" in (node.get("labels") or {})]
            assert labels and all(value == "v" * 61 for value in labels), labels

    # Conflicts are exercised independently for each actual component, with its workload enabled.
    for component, (name, version) in COMPONENTS.items():
        options = {
            "proxy.type": "haproxy" if component == "haproxy" else "proxysql",
            f"image.{component}.softwareversion": version + "@" + DIGEST,
            f"image.{component}.imageversion": BUILD + "@" + ROTATED,
        }
        render(overrides=options, failure=f"conflicting image digests for {name}:")

    # Explicit repository overrides retain their priority and are assembled by the same helper.
    docs = render(fixture="software", overrides={
        "image.database.registry": "registry.example.test:5000",
        "image.database.project": "custom/path",
        "image.database.softwarename": "custom-db",
    })
    custom = [node["image"] for doc in docs for node in walk(doc)
              if "image" in node and "custom-db:" in node["image"]]
    wanted = f"registry.example.test:5000/custom/path/custom-db:10.5.25-{BUILD}@{DIGEST}"
    assert len(custom) == 2 and all(image == wanted for image in custom), custom

    # Disabling optional workloads leaves the enabled database/config images pinned.
    docs = render(fixture="build", overrides={
        "proxy.enabled": "false", "monitoring.mysqld_exporter.enabled": "false",
        "mariadb.galera.backup.enabled": "false", "mariadb.galera.backup.kopia.enabled": "false",
    })
    images = [node["image"] for doc in docs for node in walk(doc) if "image" in node]
    assert images and all(image.endswith("@" + DIGEST) for image in images), images
    assert all(not any(name in image for name in ("-kopia:", "-proxysql:", "-mysqld_exporter:"))
               for image in images), images
    assert SITES <= SOURCES, (SITES - SOURCES)
    print(f"PASS: {RENDERS + 2} full-chart render checks (six expected conflict failures); "
          "original baseline (numeric defaults), all six "
          "components/seven template files, both pin placements, matching/conflicting pins, "
          "digest rotation, long labels, plain Kopia versions, overrides and optional workloads")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", default=BASELINE_REF)
    parser.add_argument("--baseline-chart", type=Path)
    args = parser.parse_args()
    if args.baseline_chart:
        run(args.baseline_chart.resolve())
        return
    # Extract the real original chart into temporary storage, never into the worktree.
    repo = CHART.parents[2]
    archive = subprocess.run(["git", "archive", args.baseline_ref, CHART_PATH], cwd=repo,
                             capture_output=True, check=True)
    with tempfile.TemporaryDirectory(prefix="mariadb-galera-image-digests-") as temp:
        with tarfile.open(fileobj=io.BytesIO(archive.stdout)) as tar:
            # git archive of this trusted chart only; create regular files/directories, not links.
            for member in tar.getmembers():
                path = Path(temp) / member.name
                assert path.resolve().is_relative_to(Path(temp).resolve()), member.name
                if member.isdir():
                    path.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(tar.extractfile(member).read())
                else:
                    raise AssertionError(f"unsupported archive entry: {member.name}")
        run(Path(temp) / CHART_PATH)


if __name__ == "__main__":
    main()
