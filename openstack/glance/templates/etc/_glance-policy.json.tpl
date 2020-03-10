{
    "context_is_cloud_admin":  "role:cloud_image_admin",
    "context_is_admin":  "rule:context_is_cloud_admin",
    "owner": "project_id:%(project_id)s",
    "admin": "role:image_admin and rule:owner",
    "member": "role:member and rule:owner",
    "viewer": "role:image_viewer and rule:owner",
    "context_is_image_admin":  "rule:context_is_admin or role:admin or rule:admin",
    "context_is_image_viewer":  "rule:context_is_image_admin or rule:viewer or role:member",
    "default": "rule:context_is_admin",

    "add_image": "rule:context_is_image_admin",
    "delete_image": "rule:context_is_image_admin",
    "get_image": "rule:context_is_image_viewer",
    "get_images": "rule:context_is_image_admin",
    "modify_image": "rule:context_is_image_admin",
    "publicize_image": "rule:context_is_image_admin",
    "copy_from": "rule:context_is_image_admin",

    "download_image": "rule:context_is_image_viewer",
    "upload_image": "rule:context_is_image_admin",

    "delete_image_location": "rule:context_is_image_admin",
    "get_image_location": "rule:context_is_image_viewer",
    "set_image_location": "rule:context_is_image_admin",

    "add_member": "rule:context_is_image_admin",
    "delete_member": "rule:context_is_image_admin",
    "get_member": "rule:context_is_image_viewer",
    "get_members": "rule:context_is_image_viewer",
    "modify_member": "rule:context_is_image_admin",
    "manage_image_cache": "rule:context_is_admin",

    "get_task": "rule:context_is_image_admin",
    "get_tasks": "rule:context_is_image_admin",
    "add_task": "rule:context_is_image_admin",
    "modify_task": "rule:context_is_image_admin",
    "tasks_api_access": "rule:context_is_image_admin",

    "deactivate": "rule:context_is_image_admin",
    "reactivate": "rule:context_is_image_admin",

    "get_metadef_namespace": "rule:context_is_image_viewer",
    "get_metadef_namespaces": "rule:context_is_image_viewer",
    "modify_metadef_namespace": "rule:context_is_image_admin",
    "add_metadef_namespace": "rule:context_is_image_admin",

    "get_metadef_object": "rule:context_is_image_viewer",
    "get_metadef_objects": "rule:context_is_image_viewer",
    "modify_metadef_object": "rule:context_is_image_admin",
    "add_metadef_object": "rule:context_is_image_admin",

    "list_metadef_resource_types": "rule:context_is_image_viewer",
    "get_metadef_resource_type": "rule:context_is_image_viewer",
    "add_metadef_resource_type_association": "rule:context_is_image_admin",

    "get_metadef_property": "rule:context_is_image_viewer",
    "get_metadef_properties": "rule:context_is_image_viewer",
    "modify_metadef_property": "rule:context_is_image_admin",
    "add_metadef_property": "rule:context_is_image_admin",

    "get_metadef_tag": "rule:context_is_image_viewer",
    "get_metadef_tags": "rule:context_is_image_viewer",
    "modify_metadef_tag": "rule:context_is_image_admin",
    "add_metadef_tag": "rule:context_is_image_admin",
    "add_metadef_tags": "rule:context_is_image_admin"
}
