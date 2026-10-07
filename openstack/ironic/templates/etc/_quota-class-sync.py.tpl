import sys
import openstack
import openstack.exceptions

try:
    conn = openstack.connect(timeout=60)

    nodes = list(conn.baremetal.nodes(fields=["resource_class"]))
    resource_classes = {
        n["resource_class"]
        for n in nodes
        if n.get("resource_class")
        and not n["resource_class"].startswith(("tempest-Resource_Class-", "ResClass-"))
    }
    print(f"Resource classes: {sorted(resource_classes)}")

    quotas = {"quota_class_set": {f"instances_{r}": 0 for r in resource_classes}}
    resp = conn.compute.post(
        "/os-quota-class-sets/flavors",
        json=quotas,
    )
    print(f"Response: {resp.status_code}")
except openstack.exceptions.SDKException as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
