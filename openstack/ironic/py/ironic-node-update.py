from contextlib import contextmanager
from ironicclient import client as bmclient

# import openstack # To test it locally
# os = openstack.connect()

bm = bmclient.get_client(1, session=os.session, os_ironic_api_version="1.78")

states = ["enroll", "active", "manageable", "available"]

patch_ipxe = [{"value": "ipxe", "path": "/boot_interface"}]

patch_idrac = [
    {"value": "idrac", "path": "/driver"},
    {
        "value": "idrac-redfish-virtual-media",
        "path": "/boot_interface",
    },
    {"value": "idrac-redfish-kvm", "path": "/console_interface"},
] + [
    {"value": "idrac-redfish", "path": i}
    for i in [
        "/bios_interface",
        "/management_interface",
        "/power_interface",
        "/raid_interface",
        "/vendor_interface",
    ]
]


@contextmanager
def maintenance_mode(bm, node):
    unset_maintenance = False
    try:
        if not node.maintenance:
            bm.node.set_maintenance(
                node.uuid, "true", maint_reason="updating conductor settings"
            )
            unset_maintenance = True
        yield
    except Exception as e:
        print(e)
    finally:
        if unset_maintenance:
            bm.node.set_maintenance(node.uuid, "false")


@contextmanager
def disabled_console(bm, node):
    reenable_console = False
    try:
        if node.console_enabled:
            bm.node.set_console_mode(node.uuid, "false")
            reenable_console = True
        yield
    except Exception as e:
        import traceback
        import sys

        traceback.print_exception(e, limit=2, file=sys.stdout)
    finally:
        if reenable_console:
            bm.node.set_console_mode(node.uuid, "true")


def _filtered_patch(node, patch):
    for pi in patch:
        _, *path = pi["path"].split("/")
        target_value = pi["value"]
        n = node.to_dict()
        try:
            for item in path:
                n = n[item]

            if n != target_value:
                yield {"op": "replace", **pi}
        except KeyError:
            yield {"op": "add", **pi}


def filtered_patch(node, patch):
    return list(_filtered_patch(node, patch))


for node in bm.node.list(
    limit=0,
    fields=[
        "bios_interface",
        "boot_interface",
        "conductor_group",
        "console_enabled",
        "console_interface",
        "driver",
        "driver_info",
        "maintenance",
        "management_interface",
        "name",
        "power_interface",
        "properties",
        "provision_state",
        "raid_interface",
        "resource_class",
        "uuid",
        "vendor_interface",
    ],
):
    if node.driver == "cisco-ucs-managed":
        continue
    if node.provision_state not in states:
        continue

    manufacturer = (node.properties.get("manufacturer") or "").lower()

    if manufacturer == "dell" and node.resource_class != "zh2mlx1.large":
        # zh2mlx1.large is too old
        patch = patch_idrac
    else:
        address = node.driver_info["ipmi_address"]
        username = node.driver_info["ipmi_username"]
        password = node.driver_info["ipmi_password"]
        patch = patch_ipxe + [
            {
                "path": "/driver_info/redfish_address",
                "value": "https://" + address,
            },
            {
                "path": "/driver_info/redfish_username",
                "value": username,
            },
            {
                "path": "/driver_info/redfish_password",
                "value": password,
            },
        ]

    patch = filtered_patch(node, patch)
    if not patch:
        continue

    with maintenance_mode(bm, node):
        with disabled_console(bm, node):
            bm.node.update(node_id=node.uuid, patch=patch)
