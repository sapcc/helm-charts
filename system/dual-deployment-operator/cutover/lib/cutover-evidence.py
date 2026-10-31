#!/usr/bin/env python3
"""Local evidence and whole-process bounds. Python standard library only."""
import hashlib
import base64
import gzip
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
from urllib.parse import parse_qs, urlparse


def require(ok, message):
    if not ok:
        raise ValueError(message)


def read(path):
    return json.loads(Path(path).read_text())


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def atomic(path, data):
    """Publish once, without replacing an existing inode; fsync before publication."""
    path = Path(path)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".pending-")
    try:
        with os.fdopen(fd, "wb") as out:
            out.write(data)
            out.flush()
            os.fsync(out.fileno())
        os.chmod(tmp, 0o400)
        os.link(tmp, path)  # fails if the destination already exists
        # Some platforms/filesystems do not support directory fsync: fail closed.
        dfd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(dfd)
        finally:
            os.close(dfd)
    finally:
        os.unlink(tmp)


def items(obj):
    require(isinstance(obj, dict) and obj.get("kind", "").endswith("List")
            and isinstance(obj.get("apiVersion"), str)
            and isinstance(obj.get("items"), list), "expected Kubernetes JSON List")
    seen = set()
    for item in obj["items"]:
        require(isinstance(item, dict) and isinstance(item.get("metadata"), dict), "invalid List item")
        meta = item["metadata"]
        require(isinstance(meta.get("name"), str) and bool(meta["name"]), "missing object name")
        key = (item.get("kind"), meta.get("namespace"), meta["name"])
        require(key not in seen, "duplicate inventory object")
        seen.add(key)
    return obj["items"]


def embedded_crds(manifest):
    """Decode only Secret payloads referenced by the actual CRD MRs.

    kubectl does YAML conversion later; unknown/empty payload layouts block.
    """
    objects = items(manifest)
    mrs = [o for o in objects if o.get("kind") == "ManagedResource"
           and o["metadata"]["name"].startswith("mr-crd-")]
    require(mrs, "empty legacy CRD MR inventory")
    chunks = []
    for mr in mrs:
        refs = mr.get("spec", {}).get("secretRefs")
        require(isinstance(refs, list) and refs, "CRD MR has no Secret references")
        for ref in refs:
            matches = [o for o in objects if o.get("kind") == "Secret"
                       and o["metadata"]["name"] == ref.get("name")
                       and o["metadata"].get("namespace") == mr["metadata"].get("namespace")]
            require(len(matches) == 1, "CRD MR Secret absent/ambiguous in installed manifest")
            secret = matches[0]
            payloads = [base64.b64decode(v, validate=True) for v in secret.get("data", {}).values()]
            payloads.extend(v.encode() for v in secret.get("stringData", {}).values())
            require(payloads, "empty CRD MR Secret")
            for payload in payloads:
                if payload.startswith(b"\x1f\x8b"):
                    payload = gzip.decompress(payload)
                text = payload.decode("utf-8").strip()
                require(text, "empty CRD payload")
                chunks.append(text)
    return "\n---\n".join(chunks) + "\n"


def healthy(obj, cr=False, owner=None):
    require(obj.get("kind") == ("DualDeploymentOperator" if cr else "Deployment"), "unexpected health object kind")
    m, status = obj.get("metadata", {}), obj.get("status", {})
    require(m.get("uid") and isinstance(m.get("generation"), int)
            and not m.get("deletionTimestamp"), "missing/terminating object")
    if cr:
        require(any(c.get("type") == "Ready" and c.get("status") == "True"
                    and c.get("observedGeneration", status.get("observedGeneration")) == m["generation"]
                    for c in status.get("conditions", [])), "CR not current-generation Ready")
    else:
        desired = obj.get("spec", {}).get("replicas", 1)
        require(isinstance(desired, int) and desired > 0
                and status.get("observedGeneration", -1) >= m["generation"]
                and status.get("readyReplicas", 0) >= desired
                and status.get("availableReplicas", 0) >= desired
                and status.get("updatedReplicas", 0) >= desired, "Deployment not converged")
        if owner:
            require(m.get("labels", {}).get("dual-deployment-operator.cc.sap/owned-by") == owner,
                    "wrong Deployment owner")


def identity(args):
    keys = ("operator", "cluster", "targetContext", "seedContext", "namespace", "release", "ddoCR", "deployment", "budgetSeconds", "profileContract")
    return dict(zip(keys, args))


def contract(path, run, kind, layout="original"):
    evidence = read(path)
    require(evidence.get("identity") == read(run), "evidence/run identity mismatch")
    require(evidence.get("dryRun") is False, "rehearsal is not execution evidence")
    require(isinstance(evidence.get("verifiedAtEpoch"), int)
            and 0 <= time.time() - evidence["verifiedAtEpoch"] <= 86400,
            "manual evidence must be verified within 24 hours")
    require(isinstance(evidence.get("verifiedBy"), str) and evidence["verifiedBy"].strip(), "missing verifier")
    required = {
        "freeze": ("reconciler", "originalState", "freezeProof", "restoreOnSuccess", "restoreOnRollback", "restoreOnInterruption"),
        "readiness": ("installedDDO", "installedAdmin", "sourceResolution", "expectedOwnerValue", "releasePublicationProof", "legacyArchiveProvenance", "legacyArchiveSha256"),
        "acceptance": ("functionalChecks", "doNoHarmChecks"),
    }[kind]
    for key in required:
        require(isinstance(evidence.get(key), str) and evidence[key].strip(), "missing " + key)
    if kind == "freeze":
        require(evidence.get("legacyDesiredStateDisabled") is True
                and evidence.get("restorationAvoidsDualOwnership") is True, "freeze/restore acknowledgment required")
    if kind == "readiness":
        require(evidence.get("sourcePublished") is True and evidence.get("actualRendersReviewed") is True,
                "source and actual renders must be reviewed")
        require(evidence.get("legacyArchiveMatchesInstalledRelease") is True
                and re.fullmatch(r"[0-9a-f]{64}", evidence["legacyArchiveSha256"]),
                "exact legacy archive provenance and digest acknowledgment required")
        for name in ("seedRender", "shootRender", "ddoCRManifest"):
            entry = evidence.get(name, {})
            artifact = Path(path).parent / (name + ".json" if layout == "stored" else entry.get("file", ""))
            require(artifact.is_file() and digest(artifact) == entry.get("sha256"), "missing/mismatched " + name)
            require(len(items(read(artifact))) > 0, "empty " + name)
        if read(run)["operator"] == "ipam-capi-remote":
            for key in ("ddoGitFetchVerified", "ddoHTTPFetchVerified", "adminKustomizeSourceVerified", "failPolicyPreserved", "injectorAndAdmissionRehearsed"):
                require(evidence.get(key) is True, "IPAM prerequisite missing: " + key)
            for key in ("immutableGitCommit", "gitFetchProof", "httpFetchProof", "adminRenderProof", "webhookRehearsalProof"):
                require(isinstance(evidence.get(key), str) and evidence[key].strip(), "missing IPAM " + key)
            require(re.fullmatch(r"[0-9a-f]{40}", evidence["immutableGitCommit"]), "IPAM source must resolve to full commit")
            cr_entry = evidence["ddoCRManifest"]
            crs = items(read(Path(path).parent / ("ddoCRManifest.json" if layout == "stored" else cr_entry["file"])))
            require(len(crs) == 1, "expected one reviewed DDO CR")
            source = crs[0].get("spec", {}).get("source", {}).get("kustomize", {})
            require(source.get("seedPath") and source.get("shootPath")
                    and parse_qs(urlparse(source.get("url", "")).query).get("ref") == [evidence["immutableGitCommit"]],
                    "IPAM DDO source must pin reviewed immutable commit and both overlay paths")
    if kind == "acceptance" and read(run)["operator"] == "ipam-capi-remote":
        for key in ("failPolicyPreserved", "injectorLabelsVerified", "webhookURLsVerified", "caAndCertificatesVerified", "endpointReachabilityVerified", "admissionAllowedAndDeniedVerified"):
            require(evidence.get(key) is True, "IPAM acceptance missing: " + key)
    return evidence


def main():
    cmd, *args = sys.argv[1:]
    if cmd == "run":
        seconds = float(args.pop(0))
        require(seconds > 0, "deadline exhausted")
        proc = subprocess.Popen(args, start_new_session=True)
        def interrupted(signum, _frame):
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
            sys.exit(128 + signum)
        signal.signal(signal.SIGTERM, interrupted)
        signal.signal(signal.SIGINT, interrupted)
        try:
            return proc.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
            print("whole-process deadline exceeded", file=sys.stderr)
            return 124
    if cmd == "publish":
        atomic(args[0], Path(args[1]).read_bytes())
    elif cmd == "identity":
        print(json.dumps(identity(args), sort_keys=True))
    elif cmd == "list":
        items(read(args[0]))
    elif cmd == "embedded-crds":
        print(embedded_crds(read(args[0])), end="")
    elif cmd == "crd-coverage":
        expected, live = items(read(args[0])), items(read(args[1]))
        require(expected and all(o.get("kind") == "CustomResourceDefinition" for o in expected), "invalid/empty rendered CRD payload")
        by_name = {o["metadata"]["name"]: o for o in live}
        for crd in expected:
            observed = by_name.get(crd["metadata"]["name"], {})
            require(observed.get("metadata", {}).get("uid") and not observed["metadata"].get("deletionTimestamp")
                    and observed.get("spec", {}).get("group") == crd.get("spec", {}).get("group"),
                    "installed legacy CRD missing/terminating: " + crd["metadata"]["name"])
    elif cmd == "normalize":
        text = Path(args[0]).read_text().strip()
        decoder, result = json.JSONDecoder(), []
        while text:
            obj, end = decoder.raw_decode(text)
            result.extend(items(obj) if obj.get("kind", "").endswith("List") else [obj])
            text = text[end:].lstrip()
        obj = {"apiVersion": "v1", "kind": "List", "items": result}
        require(items(obj), "empty manifest")
        print(json.dumps(obj))
    elif cmd == "seal":
        root = Path(args[0])
        hashes = {p.name: digest(p) for p in root.iterdir() if p.is_file() and p.name != "checksums.json"}
        require(hashes, "empty evidence")
        atomic(root / "checksums.json", json.dumps(hashes, sort_keys=True).encode())
        for name in hashes:
            os.chmod(root / name, 0o400)
            with open(root / name, "rb") as stored:
                os.fsync(stored.fileno())
    elif cmd == "commit":
        require(not Path(args[1]).exists(), "refusing to overwrite evidence directory")
        os.rename(args[0], args[1])
        fd = os.open(Path(args[1]).parent, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    elif cmd == "check":
        root = Path(args[0])
        hashes = read(root / "checksums.json")
        require(hashes and set(hashes) == {p.name for p in root.iterdir() if p.is_file() and p.name != "checksums.json"}, "evidence file set changed")
        for name, sha in hashes.items():
            require(Path(name).name == name and digest(root / name) == sha, "evidence altered: " + name)
    elif cmd == "contract":
        contract(*args)
    elif cmd == "healthy":
        healthy(read(args[0]), args[1] == "cr", args[2] if len(args) > 2 else None)
    elif cmd == "chart":
        archive, releases, release, legacy_name = args
        with tarfile.open(archive, "r:gz") as tar:
            names = [m for m in tar.getmembers() if len(Path(m.name).parts) == 2 and m.name.endswith("/Chart.yaml") and m.isfile()]
            require(len(names) == 1, "archive must contain one root Chart.yaml")
            text = tar.extractfile(names[0]).read().decode()
        def field(name):
            values = re.findall(r"^" + name + r":\s*([^\n]+)\s*$", text, re.M)
            require(len(values) == 1, "ambiguous chart " + name)
            return values[0].strip().strip("\"'")
        name, version = field("name"), field("version")
        require(name == legacy_name and not name.endswith("-ddo"), "not the legacy chart")
        rows = [r for r in read(releases) if r.get("name") == release]
        require(len(rows) == 1 and rows[0].get("chart") == name + "-" + version
                and rows[0].get("status") == "deployed", "archive differs from installed legacy chart/version")
    elif cmd == "baseline":
        obj = read(args[0])
        for item in items(obj):
            require(item["metadata"].get("uid") and not item["metadata"].get("deletionTimestamp"), "missing UID or terminating baseline object")
        if len(args) > 1 and args[1] == "ipam-known-two":
            actual = {(i["metadata"].get("namespace"), i["metadata"]["name"]): i["metadata"]["uid"] for i in items(obj)}
            require(actual.get(("metal-servers", "globalinclusterippool-mgmt-qa-de-200")) == "83614ed7-f367-4bd0-acdd-4fbd4de76eec", "IPAM management pool UID invariant failed")
            require(actual.get(("metal-servers", "test")) == "d7d99994-c27d-4116-835b-4d858069b7ea", "IPAM test pool UID invariant failed")
    else:
        raise ValueError("unknown operation: " + cmd)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError, TypeError, tarfile.TarError) as exc:
        print("evidence blocked: " + str(exc), file=sys.stderr)
        sys.exit(2)
