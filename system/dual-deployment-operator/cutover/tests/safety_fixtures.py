"""Synthetic local fixtures for safety_test.sh; never contacts a cluster."""
import base64
import hashlib
import io
import json
from pathlib import Path
import sys
import tarfile
import time

root = Path(sys.argv[1])
identity = json.loads((root / "identity.json").read_text())


def write(name, obj):
    (root / name).write_text(json.dumps(obj))


def listing(*objects):
    return {"apiVersion": "v1", "kind": "List", "items": list(objects)}


def artifact(name, obj):
    write(name + ".json", obj)
    return {"file": name + ".json", "sha256": hashlib.sha256((root / (name + ".json")).read_bytes()).hexdigest()}


crd = {"apiVersion": "apiextensions.k8s.io/v1", "kind": "CustomResourceDefinition",
       "metadata": {"name": "globalinclusterippools.ipam.cluster.x-k8s.io", "uid": "crd-uid"},
       "spec": {"group": "ipam.cluster.x-k8s.io"}}
write("crds.json", listing(crd))
pools = []
for name, uid in [("globalinclusterippool-mgmt-qa-de-200", "83614ed7-f367-4bd0-acdd-4fbd4de76eec"),
                  ("test", "d7d99994-c27d-4116-835b-4d858069b7ea")]:
    pools.append({"apiVersion": "ipam.cluster.x-k8s.io/v1alpha2", "kind": "GlobalInClusterIPPool",
                  "metadata": {"name": name, "namespace": "metal-servers", "uid": uid}})
write("pools.json", listing(*pools))
mr = {"apiVersion": "resources.gardener.cloud/v1alpha1", "kind": "ManagedResource",
      "metadata": {"name": "mr-crd-pools", "namespace": "cp", "annotations": {"meta.helm.sh/release-name": "legacy"}},
      "spec": {"keepObjects": True, "secretRefs": [{"name": "crds"}]}}
secret = {"apiVersion": "v1", "kind": "Secret", "metadata": {"name": "crds", "namespace": "cp"},
          "data": {"crds.yaml": base64.b64encode(json.dumps(crd).encode()).decode()}}
write("manifest.json", listing(mr, secret))
write("mrs.json", listing(mr))
controller = {"apiVersion": "apps/v1", "kind": "Deployment",
              "metadata": {"name": "actual-ddo", "namespace": "actual-system", "uid": "controller-uid", "generation": 4},
              "spec": {"replicas": 3, "selector": {"matchLabels": {"app": "actual-ddo"}}},
              "status": {"observedGeneration": 4, "readyReplicas": 3, "availableReplicas": 3, "updatedReplicas": 3}}
write("controllers.json", listing(controller))
write("releases.json", [{"name": "legacy", "chart": "ipam-capi-remote-0.21.0", "status": "deployed", "revision": "7"}])
with tarfile.open(root / "legacy.tgz", "w:gz") as tar:
    content = b"apiVersion: v2\nname: ipam-capi-remote\nversion: 0.21.0\n"
    info = tarfile.TarInfo("ipam-capi-remote/Chart.yaml")
    info.size = len(content)
    tar.addfile(info, io.BytesIO(content))
common = {"identity": identity, "dryRun": False, "verifiedBy": "fixture-operator", "verifiedAtEpoch": int(time.time())}
freeze = dict(common, legacyDesiredStateDisabled=True, restorationAvoidsDualOwnership=True)
for key in ("reconciler", "originalState", "freezeProof", "restoreOnSuccess", "restoreOnRollback", "restoreOnInterruption"):
    freeze[key] = "fixture " + key
write("freeze.json", freeze)
commit = "a" * 40
ddo = {"apiVersion": "dual-deployment-operator.cc.sap/v1alpha1", "kind": "DualDeploymentOperator",
       "metadata": {"name": identity["ddoCR"], "namespace": identity["namespace"]},
       "spec": {"source": {"kustomize": {"url": "https://example.invalid/repo?ref=" + commit, "seedPath": "seed", "shootPath": "shoot"}}}}
ready = dict(common, sourcePublished=True, actualRendersReviewed=True, legacyArchiveMatchesInstalledRelease=True,
             legacyArchiveSha256=hashlib.sha256((root / "legacy.tgz").read_bytes()).hexdigest(), immutableGitCommit=commit)
for key in ("installedDDO", "installedAdmin", "sourceResolution", "expectedOwnerValue", "releasePublicationProof", "legacyArchiveProvenance",
            "gitFetchProof", "httpFetchProof", "adminRenderProof", "webhookRehearsalProof"):
    ready[key] = "fixture " + key
for key in ("ddoGitFetchVerified", "ddoHTTPFetchVerified", "adminKustomizeSourceVerified", "failPolicyPreserved", "injectorAndAdmissionRehearsed"):
    ready[key] = True
ready["seedRender"] = artifact("seedRender", listing(controller))
ready["shootRender"] = artifact("shootRender", listing(crd))
ready["ddoCRManifest"] = artifact("ddoCRManifest", listing(ddo))
write("readiness.json", ready)
