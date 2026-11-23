#!/usr/bin/env python3
"""Integrated G01/G02 regression tests (Python stdlib, Helm and yq v4).

From the repo root: helm dependency build global/cc-gardener
                   python3 global/cc-gardener/ci/test-image-digests.py
From the chart:     helm dependency build . && python3 ci/test-image-digests.py

The original chart is archived from --baseline-ref and rendered using the same
real, unmodified dependencies. No dummy helpers or chart metadata edits are used.
"""

import argparse
import base64
import copy
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


CHART = Path(__file__).resolve().parents[1]
CI = CHART / "ci"
BASELINE_REF = "04f4dbf7da48feb93e052fe1e2597f8415cae1e1"
DIGEST = "sha256:" + "1" * 64
ROTATED_DIGEST = "sha256:" + "2" * 64
OPERATOR_TAG = "v1.144.2"
INJECTOR_TAG = "v1.2.3"
INJECTOR_REPO = "registry.example.com:5000/secrets-injector"
LABEL = re.compile(r"(?:[A-Za-z0-9](?:[-_.A-Za-z0-9]*[A-Za-z0-9])?)?")
JOB_NAME = re.compile(r"[a-z0-9](?:[-a-z0-9]*[a-z0-9])?")


def yaml_documents(text):
    result = subprocess.run(
        ["yq", "eval-all", "-o=json", "-I=0", ".", "-"],
        input=text, text=True, capture_output=True, check=True,
    )
    decoder = json.JSONDecoder()
    remaining = result.stdout.strip()
    documents = []
    while remaining:
        value, end = decoder.raw_decode(remaining)
        if value is not None:
            documents.append(value)
        remaining = remaining[end:].lstrip()
    return documents


def render(fixture="ordinary", overrides=None, chart=CHART, release="digest-test"):
    command = [
        "helm", "template", release, str(chart), "--namespace", "garden",
        "-f", str(CI / f"image-digests-{fixture}-values.yaml"),
    ]
    if overrides:
        # JSON is a YAML subset; stdin overrides retain nulls and explicit strings.
        command.extend(["-f", "-"])
    result = subprocess.run(command, input=json.dumps(overrides or {}),
                            text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(f"{' '.join(command)} failed:\n{result.stderr}")
    documents = yaml_documents(result.stdout)
    secrets = {doc["metadata"]["name"]: doc for doc in documents
               if doc.get("kind") == "Secret"}
    for resource in documents:
        if resource.get("kind") != "ManagedResource":
            continue
        for reference in resource["spec"]["secretRefs"]:
            secret = secrets[reference["name"]]
            objects = base64.b64decode(secret["data"]["objects.yaml"], validate=True)
            decoded = yaml_documents(objects.decode())
            assert decoded, f"empty ManagedResource {resource['metadata']['name']}"
            # Decode the actual wrapper Secret, not a helper or copied template.
            secret["data"]["objects.yaml"] = decoded
    for document in documents:
        check_metadata(document)
    return documents


def check_metadata(value):
    if isinstance(value, dict):
        metadata = value.get("metadata", {})
        if isinstance(metadata, dict):
            for key, label in (metadata.get("labels") or {}).items():
                label = str(label)
                assert len(label) <= 63 and LABEL.fullmatch(label), (key, label)
            if value.get("kind") == "Job":
                name = metadata["name"]
                assert len(name) <= 63 and JOB_NAME.fullmatch(name), name
        for child in value.values():
            check_metadata(child)
    elif isinstance(value, list):
        for child in value:
            check_metadata(child)


def objects(documents, kind):
    found = [doc for doc in documents if doc.get("kind") == kind]
    for document in documents:
        if document.get("kind") == "Secret":
            for obj in (document.get("data") or {}).get("objects.yaml", []):
                if obj.get("kind") == kind:
                    found.append(obj)
    return found


def injector(documents):
    deployments = [doc for doc in objects(documents, "Deployment")
                   if doc["metadata"]["name"] == "secrets-injector-watcher"]
    assert len(deployments) == 1, "enabled secrets-injector Deployment missing"
    return deployments[0]["spec"]["template"]["spec"]["containers"][0]


def gardenlets(documents, count=2):
    found = objects(documents, "Gardenlet")
    assert len(found) == count, "decoded ManagedResource Gardenlets missing"
    return found


def check_fallback(documents, operator_pin, injector_pin):
    separator = "@" if injector_pin.startswith("sha256:") else ":"
    assert injector(documents)["image"] == INJECTOR_REPO + separator + injector_pin
    assert injector(documents)["image"].count("@") == injector_pin.count("@") + (separator == "@")
    for gardenlet in gardenlets(documents):
        deployment = gardenlet["spec"]["deployment"]
        assert deployment["image"]["tag"] == operator_pin
        assert deployment["helm"]["ociRepository"]["tag"] == operator_pin.split("@")[0]


def baseline_chart(reference, directory):
    repo = Path(subprocess.check_output(
        ["git", "-C", str(CHART), "rev-parse", "--show-toplevel"], text=True,
    ).strip())
    relative = CHART.relative_to(repo)
    archive = subprocess.check_output(["git", "archive", reference, str(relative)], cwd=repo)
    subprocess.run(["tar", "-x", "-C", str(directory)], input=archive, check=True)
    baseline = directory / relative
    if not (CHART / "charts").is_dir():
        raise AssertionError("real dependencies missing: run helm dependency build global/cc-gardener")
    shutil.copytree(CHART / "charts", baseline / "charts")
    return baseline


def check_original(reference):
    with tempfile.TemporaryDirectory(prefix="cc-gardener-baseline-", dir=os.environ.get("TMPDIR")) as temporary:
        baseline = baseline_chart(reference, Path(temporary))
        original = render(chart=baseline)
        fixed = render()
        # G01 deliberately fixes the formerly invalid repository@ordinary-tag.
        assert injector(original)["image"] == INJECTOR_REPO + "@" + INJECTOR_TAG
        injector(original)["image"] = INJECTOR_REPO + ":" + INJECTOR_TAG
        assert original == fixed, "ordinary output changed beyond the intended G01 separator fix"

        # The legacy digest-only branch must remain byte-for-byte equivalent as YAML objects.
        legacy = {"secretsInjector": {"image": {"tag": DIGEST}}}
        assert render(overrides=legacy, chart=baseline) == render(overrides=legacy)

        # Exercise ordinary explicit Gardenlet/OCI overrides against original output too.
        explicit = {
            "gardenlet": {
                "image": {"repository": "example.com/gardenlet", "tag": "custom"},
                "helm": {"ociRepository": {
                    "repository": "example.com/charts/gardenlet", "tag": "custom-chart",
                    "pullSecretRef": {"name": "chart-pull-secret"},
                }},
            },
            **legacy,
        }
        assert render(overrides=explicit, chart=baseline) == render(overrides=explicit)
        explicit["gardenlet"]["helm"]["ociRepository"]["ref"] = "example.com/charts/gardenlet:custom@" + DIGEST
        assert render(overrides=explicit, chart=baseline) == render(overrides=explicit)
        # Chart.yaml has no appVersion: retain the existing empty/null fallback.
        for tag in ("", None):
            empty = {"operator": {"image": {"tag": tag}}, **legacy}
            assert render(overrides=empty, chart=baseline) == render(overrides=empty)
    print(f"PASS: actual original-commit comparison ({reference}); ordinary, legacy and overrides")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", default=BASELINE_REF)
    args = parser.parse_args()
    check_original(args.baseline_ref)

    ordinary = render()
    pinned = render("pinned")
    check_fallback(ordinary, OPERATOR_TAG, INJECTOR_TAG)
    check_fallback(pinned, OPERATOR_TAG + "@" + DIGEST, INJECTOR_TAG + "@" + DIGEST)
    normalized = copy.deepcopy(pinned)
    injector(normalized)["image"] = injector(ordinary)["image"]
    for gardenlet in gardenlets(normalized):
        gardenlet["spec"]["deployment"]["image"]["tag"] = OPERATOR_TAG
    assert normalized == ordinary, "pinning changed unrelated manifests or chart selectors"
    numeric = render(overrides={"secretsInjector": {"image": {"tag": 42}}})
    assert injector(numeric)["image"] == INJECTOR_REPO + ":42"
    print("PASS: full ordinary/pinned renders; actual decoded Gardenlets; enabled injector; only images differ")

    rotated_operator = OPERATOR_TAG + "@" + ROTATED_DIGEST
    rotated_injector = INJECTOR_TAG + "@" + ROTATED_DIGEST
    rotated = render("pinned", {
        "operator": {"image": {"tag": rotated_operator}},
        "secretsInjector": {"image": {"tag": rotated_injector}},
    })
    check_fallback(rotated, rotated_operator, rotated_injector)
    long_pin = "v" + "x" * 120 + "@" + DIGEST
    long_output = render("pinned", {
        "operator": {"image": {"tag": long_pin}},
        "secretsInjector": {"image": {"tag": long_pin}},
        "gardenlet": {"namePrefix": "seed-" + "a" * 35},
    }, release="r" * 53)
    check_fallback(long_output, long_pin, long_pin)
    print("PASS: digest rotation; long image tag/release/prefix; Kubernetes metadata labels validated")

    image_override = {"repository": "custom.example.com:5000/gardenlet", "tag": "v2@" + ROTATED_DIGEST}
    selectors = [
        {"repository": "example.com/charts/gardenlet", "tag": "v2.0.0"},
        # Explicit tag contents are never globally rewritten by the OCI helper.
        {"repository": "example.com/charts/gardenlet", "tag": "v2@" + ROTATED_DIGEST},
        {"repository": "example.com/charts/gardenlet", "digest": ROTATED_DIGEST},
        {"repository": "example.com/charts/gardenlet", "digest": ROTATED_DIGEST, "tag": "v3.0.0"},
        {"ref": "example.com/charts/gardenlet:v2@" + ROTATED_DIGEST,
         "repository": "conflicting.example.com/chart", "tag": "ignored"},
    ]
    for selector in selectors:
        selector = {**selector, "pullSecretRef": {"name": "private-chart"}}
        output = render("pinned", {"gardenlet": {
            "image": image_override, "helm": {"ociRepository": selector},
        }})
        for gardenlet in gardenlets(output):
            deployment = gardenlet["spec"]["deployment"]
            assert deployment["image"] == image_override
            oci = deployment["helm"]["ociRepository"]
            assert oci["pullSecretRef"] == selector["pullSecretRef"]
            if "ref" in selector:
                assert oci["ref"] == selector["ref"]
                assert oci["repository"] is None and oci["tag"] is None
            else:
                assert oci["ref"] is None
                assert oci["repository"] == selector["repository"]
                assert oci["tag"] == selector.get("tag", OPERATOR_TAG)
                if "digest" in selector:
                    assert oci["digest"] == selector["digest"]
        assert injector(output)["image"] == INJECTOR_REPO + ":" + INJECTOR_TAG + "@" + DIGEST
    print("PASS: explicit OCI tag/ref/digest/pull secrets and pinned Gardenlet image overrides; ref conflict precedence")

    # Override only the Gardenlet image: the chart must still use the operator tag.
    for override in ({"tag": "custom"}, {"tag": ""}, None):
        output = render("pinned", {"gardenlet": {"image": override}})
        expected_tag = "custom" if override and override.get("tag") else OPERATOR_TAG + "@" + DIGEST
        for gardenlet in gardenlets(output):
            deployment = gardenlet["spec"]["deployment"]
            assert deployment["image"]["tag"] == expected_tag
            assert deployment["helm"]["ociRepository"]["tag"] == OPERATOR_TAG
    output = render("pinned", {"gardenlet": {"helm": {"ociRepository": None}}})
    for gardenlet in gardenlets(output):
        oci = gardenlet["spec"]["deployment"]["helm"]["ociRepository"]
        assert oci == {"ref": None, "tag": OPERATOR_TAG}

    # Preserve extension chart-version/image independence and unrelated OCI pins.
    extension_ref = "example.com/charts/provider-aws:v1.70.0@" + ROTATED_DIGEST
    output = render("pinned", {"extensions": {"aws": {
        "version": "v1.70.0",
        "values": {"image": {"tag": "v1.70.0@" + ROTATED_DIGEST}},
        "helm": {"ociRepository": {"ref": extension_ref}},
    }}})
    aws = next(doc for doc in objects(output, "Extension") if doc["metadata"]["name"] == "provider-aws")
    extension = aws["spec"]["deployment"]["extension"]
    assert extension["values"]["image"]["tag"] == "v1.70.0@" + ROTATED_DIGEST
    assert extension["runtimeClusterValues"]["image"]["tag"] == "v1.70.0@" + ROTATED_DIGEST
    assert extension["helm"]["ociRepository"]["ref"] == extension_ref
    print("PASS: image-only/empty/null overrides and unchanged extension OCI/image behavior")

    disabled = render("pinned", {
        "gardenlet": {"enabled": False}, "secretsInjector": {"enabled": False},
    })
    assert not objects(disabled, "Gardenlet")
    assert not any(doc["metadata"]["name"] == "secrets-injector-watcher"
                   for doc in objects(disabled, "Deployment"))
    unmanaged = render("pinned", {"garden": {"managedresources": False}})
    assert not objects(unmanaged, "Gardenlet")
    assert not objects(unmanaged, "ManagedResource")
    assert injector(unmanaged)["image"] == INJECTOR_REPO + ":" + INJECTOR_TAG + "@" + DIGEST
    print("PASS: optional Gardenlet/injector and ManagedResource enablement paths")

    for overrides, message in [
        ({"global": {"registry": ""}}, ".Values.global.registry is missing"),
        ({"secretsInjector": {"image": {"tag": ""}}}, ".Values.secretsInjector.image.tag is missing"),
    ]:
        try:
            render(overrides=overrides)
        except AssertionError as error:
            assert message in str(error), str(error)
        else:
            raise AssertionError("existing required-value validation was lost")
    print("PASS: existing required registry/tag handling preserved")


if __name__ == "__main__":
    main()
