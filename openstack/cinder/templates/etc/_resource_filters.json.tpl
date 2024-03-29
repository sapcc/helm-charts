{
    "volume": ["name", "name~", "status", "metadata",
               "bootable", "migration_status", "availability_zone",
               "group_id", "user_id", "description~"],
    "backup": ["name", "status", "volume_id", "description~"],
    "snapshot": ["name", "name~", "status", "volume_id", "metadata",
                 "availability_zone"],
    "group": [],
    "group_snapshot": ["status", "group_id"],
    "attachment": ["volume_id", "status", "instance_id", "attach_status"],
    "message": ["resource_uuid", "resource_type", "event_id",
                "request_id", "message_level"],
    "pool": ["name", "volume_type"],
    "volume_type": ["is_public"]
}
