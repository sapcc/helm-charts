#!/usr/bin/env python3
"""Fence schema contraction on a complete, revision-specific Keystone rollout.

Uses only the Python standard library and the pod's Kubernetes service account.
Service endpoints and Deployment Available alone can both refer to old pods.
"""

import json
import os
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


REVISION = "cloud.sap/keystone-revision"
RELEASE = "cloud.sap/keystone-release"
WRITERS = {
    "keystone-db-expansion", "keystone-db-contraction",
    "keystone-api", "keystone-repair-assignments",
    "keystone-bootstrap", "keystone-credential-migrate",
}


def labels(obj):
    return obj.get("metadata", {}).get("labels", {})


def finished(job):
    return any(c.get("type") in ("Complete", "Failed") and c.get("status") == "True"
               for c in job.get("status", {}).get("conditions", []))


def writer_containers(pod):
    return [c for c in pod.get("spec", {}).get("containers", []) if c["name"] in WRITERS]


def target_template(kind, name, template, revision, container, image, pending):
    actual_revision = labels(template).get(REVISION, "0")
    if actual_revision.isdigit() and int(actual_revision) > int(revision):
        raise RuntimeError(f"{kind} {name} superseded revision {revision} with {actual_revision}")
    if actual_revision != revision:
        pending.append(f"{kind} {name} has not received revision {revision}")
        return False
    actual_images = {c["name"]: c["image"] for c in template["spec"]["containers"]}
    if actual_images.get(container) != image:
        raise RuntimeError(f"{kind} {name} has an unexpected Keystone image")
    return True


def pending_rollout(release, revision, image, deployments, replicasets, pods, jobs):
    """Check release-labelled pipeline workloads; reject a superseded rollout."""
    pending = []
    name = f"{release}-api"
    dep = deployments.get(name)
    if dep is None:
        pending.append(f"Deployment {name} does not exist yet")
    else:
        current = target_template("Deployment", name, dep["spec"]["template"], revision,
                                  "keystone-api", image, pending)
        desired = dep["spec"].get("replicas", 1)
        if current and desired < 1:
            raise RuntimeError("At least one API replica is required to finalize an upgrade")
        status = dep.get("status", {})
        if status.get("observedGeneration", 0) < dep["metadata"]["generation"]:
            pending.append(f"Deployment {name} generation is not observed")
        for key in ("replicas", "updatedReplicas", "readyReplicas", "availableReplicas"):
            if status.get(key, 0) != desired:
                pending.append(f"Deployment {name}: {key}={status.get(key, 0)}, expected {desired}")

    for rs in replicasets:
        template = rs["spec"]["template"]
        if labels(template).get(RELEASE) != release:
            continue
        if not any(c["name"] == "keystone-api" for c in writer_containers(template)):
            continue
        if labels(template).get(REVISION) != revision:
            if rs["spec"].get("replicas", 0) or rs.get("status", {}).get("replicas", 0):
                pending.append(f"Old ReplicaSet {rs['metadata']['name']} still has replicas")

    for job in jobs:
        template = job["spec"]["template"]
        if labels(template).get(RELEASE) != release:
            continue
        if not writer_containers(template):
            continue
        if labels(template).get(REVISION) != revision and not finished(job):
            # A non-terminal Job can create another old-version pod between
            # retries even when it currently has no active pods.
            if not job["metadata"].get("deletionTimestamp"):
                pending.append(f"Old Job {job['metadata']['name']} can still run")

    ready_api_pods = 0
    for pod in pods:
        containers = writer_containers(pod)
        if (labels(pod).get(RELEASE) != release or not containers
                or pod.get("status", {}).get("phase") in ("Succeeded", "Failed")):
            continue
        name = pod["metadata"]["name"]
        if labels(pod).get(REVISION) != revision:
            pending.append(f"Old pod {name} has not terminated")
            continue
        for container in containers:
            if container["image"] != image:
                pending.append(f"Pod {name} has an unexpected Keystone image in {container['name']}")
        if any(c["name"] == "keystone-api" for c in containers):
            if pod["metadata"].get("deletionTimestamp"):
                pending.append(f"API pod {name} is still draining")
            elif any(c.get("type") == "Ready" and c.get("status") == "True"
                     for c in pod.get("status", {}).get("conditions", [])):
                ready_api_pods += 1
            else:
                pending.append(f"API pod {name} is not ready")

    desired_api = (deployments.get(f"{release}-api") or {}).get("spec", {}).get("replicas", 1)
    if ready_api_pods != desired_api:
        pending.append(f"Observed {ready_api_pods} ready target API pods, expected {desired_api}")
    return pending


class Kubernetes:
    def __init__(self, namespace):
        directory = Path("/var/run/secrets/kubernetes.io/serviceaccount")
        self.token = directory / "token"
        self.context = ssl.create_default_context(cafile=str(directory / "ca.crt"))
        host = os.environ["KUBERNETES_SERVICE_HOST"]
        if ":" in host:
            host = f"[{host}]"
        self.url = f"https://{host}:{os.environ.get('KUBERNETES_SERVICE_PORT_HTTPS', '443')}"
        self.namespace = urllib.parse.quote(namespace, safe="")

    def get(self, path):
        request = urllib.request.Request(self.url + path, headers={
            "Authorization": "Bearer " + self.token.read_text().strip(),
        })
        try:
            with urllib.request.urlopen(request, context=self.context) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if error.code in (401, 403):
                raise RuntimeError(f"Kubernetes API denied access to {path}: HTTP {error.code}") from error
            raise

    def path(self, api, resource):
        return f"/{api}/namespaces/{self.namespace}/{resource}"

    def list(self, api, resource):
        result = []
        query = {"labelSelector": "component=keystone", "limit": "500"}
        while True:
            page = self.get(self.path(api, resource) + "?" + urllib.parse.urlencode(query))
            if page is None:
                raise RuntimeError(f"Kubernetes resource API missing: {api}/{resource}")
            result.extend(page["items"])
            token = page.get("metadata", {}).get("continue")
            if not token:
                return result
            query["continue"] = token

    def snapshot(self, release):
        deployments = {
            f"{release}-api": self.get(self.path("apis/apps/v1", f"deployments/{release}-api")),
        }
        replicasets = self.list("apis/apps/v1", "replicasets")
        jobs = self.list("apis/batch/v1", "jobs")
        # Read controllers before their children so old Jobs/pods created
        # while the templates are being updated are included in this check.
        pods = self.list("api/v1", "pods")
        return deployments, replicasets, pods, jobs


def wait_for_rollout(client, release, revision, image):
    previous = None
    while True:
        try:
            pending = pending_rollout(release, revision, image, *client.snapshot(release))
        except (urllib.error.URLError, TimeoutError) as error:
            pending = [f"Kubernetes API temporarily unavailable: {error}"]
        if not pending:
            print(f"Keystone revision {revision}: rollout complete; no old writers remain.", flush=True)
            return
        message = "; ".join(pending)
        if message != previous:
            print("Waiting: " + message, flush=True)
            previous = message
        time.sleep(5)


def main():
    client = Kubernetes(os.environ["KEYSTONE_NAMESPACE"])
    wait_for_rollout(client, os.environ["KEYSTONE_RELEASE"], os.environ["KEYSTONE_REVISION"],
                     os.environ["KEYSTONE_API_IMAGE"])


if __name__ == "__main__":
    main()
