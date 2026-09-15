service_type: 'storage/volume'
service_name: 'cinder'

# capture the target project (e.g. for cross-project calls)
prefix: '/v[0-9\.]*/(?P<project_id>[0-9a-f\-]+)'

resources:
  attachments:
    custom_actions:
      details: read/list/details
      os-complete: update/complete
  availability-zones:
    api_name: os-availability-zone
    singleton: true
  backups:
    custom_actions:
      # model details listing a action
      details: read/list/details
      export_record: read/export
      import_record: update/import
      os-force_delete: delete/forced
      os-reset_status: update/set/status
      restore: restore
  capabilities:
    singleton: true
  clusters:
    custom_actions:
      details: read/list/details
      # path-encoded actions: PUT /clusters/enable or /clusters/disable
      enable: enable
      disable: disable
  consistency-groups:
    api_name: consistencygroups
    custom_actions:
      create_from_src: create/from-snapshot
      delete: delete
      # model details listing a action
      details: read/list/details
      update: update/diff/volumes
  consistency-group-snapshots:
    api_name: cgsnapshots
    custom_actions:
      # model details listing a action
      details: read/list/details
  default-types:
    api_name: default-types
  extensions:
  groups:
    custom_actions:
      delete: delete
      # model details listing a action
      details: read/list/details
      disable_replication: disable/replication
      enable_replication: enable/replication
      failover_replication: update/failover
      list_replication_targets: read/list/replication-targets
      reset_status: update/set/status
  group-snapshots:
    api_name: group_snapshots
    custom_actions:
      # model details listing a action
      details: read/list/details
      reset_status: update/set/status
  group-types:
    api_name: group_types
    children:
      group-specs:
        api_name: group_specs
  hosts:
    api_name: os-hosts
  limits:
    singleton: true
  manageable-snapshots:
    api_name: manageable_snapshots
    custom_actions:
      # model details listing a action
      details: read/list/details
  manageable_volumes:
    custom_actions:
      # model details listing a action
      details: read/list/details
  messages:
  resource_filters:
    singleton: true
  qos-specs:
    custom_actions:
      delete_keys: update/unset-keys
      disassociate_all: update/disassociate/all
      associate: update/associate
      disassociate: update/disassociate
    children:
      associations:
        singleton: true
  quota-classes:
    api_name: os-quota-class-sets
    el_type_uri: network/quota-class
  quotas:
    api_name: os-quota-sets
    custom_actions:
      validate_setup_for_nested_quota_use: read/validate
    children:
      defaults:
        singleton: true
  sap-contrib:
    api_name: os-sap-contrib
    singleton: true
    custom_actions:
      # path-encoded actions: PUT /os-sap-contrib/{action}
      recount_host_stats: update/recount-host-stats
      set_pool_state: update/set/pool-state
      set_aggregate_id: update/set/aggregate-id
      get_aggregate_id: read/aggregate-id
  scheduler-stats:
    singleton: true
    children:
      pools:
        # nice API design again
        api_name: get_pools
  services:
      api_name: os-services
      custom_actions:
          disable: disable
          disable-log-reason: disable
          enable: enable
          failover: update/failover/host
          failover_host: update/failover/host
          freeze: disable/freeze/host
          get-log: read/get/log-levels
          set-log: update/set/log-levels
          thaw: enable/thaw/host
  snapshots:
    custom_actions:
      # model details listing a action
      details: read/list/details
      os-reset_status: update/set/status
      os-unmanage: undeploy
      os-update_snapshot_status: update/set/status
    children:
      metadata:
        singleton: true
        type_name: meta
  transfers:
    payloads:
      exclude:
        - auth_key
    # the API path is funny
    api_name: os-volume-transfer
    # the JSON name is fine again
    type_name: transfers
    custom_actions:
      accept: update/accept
  types:
    custom_actions:
      addProjectAccess: allow/project-access
      removeProjectAccess: deny/project-access
    children:
      encryption-types:
        # warning: this API design is 'special' to put it mildly
        # singular
        api_name: encryption
        # as a result of the above
        el_type_name: encryption
        custom_id: encryption_id
      extra-specs:
        api_name: extra_specs
        singleton: true
      volume-type-access:
        singleton: true
        api_name: os-volume-type-access
        type_uri: storage/volume/type/project-acl
  volume-transfers:
    # v3 microversion path (coexists with os-volume-transfer)
    api_name: volume-transfers
    type_uri: storage/volume/transfers
    type_name: transfers
    payloads:
      exclude:
        - auth_key
    custom_actions:
      accept: update/accept
      details: read/list/details
  volumes:
    custom_actions:
      # model details listing a action
      details: read/list/details
      os-attach: update/attach
      os-begin_detaching: update/begin-detach
      os-detach: update/detach
      os-extend: update/extend
      os-extend_volume_completion: update/extend/complete
      os-force_delete: delete/forced
      os-force_detach: update/detach/forced
      os-initialize_connection: update/initialize-connection
      os-migrate_volume: update/migrate
      os-migrate_volume_completion: update/migrate/complete
      os-migrate_volume_by_connector: update/migrate/by-connector
      os-reimage: update/reimage
      os-reserve: update/reserve
      os-reset_status: update/set/status
      os-retype: update/retype
      os-roll_detaching: update/roll-detach
      os-set_bootable: update/set/bootable
      os-terminate_connection: update/terminate-connection
      os-unreserve: update/unreserve
      os-update_readonly_flag: update/set/readonly
      os-volume_upload_image: capture/image
      # warning: odd API design
      os-set_image_metadata: update/set/metadata
      os-unmanage: undeploy
      os-unset_image_metadata: update/unset/metadata
      os-show_image_metadata: read/metadata
      revert: restore/revert
      summary: read/summary
    children:
      metadata:
        singleton: true
        type_name: meta
  workers:
    singleton: true
    custom_actions:
      cleanup: update/cleanup
