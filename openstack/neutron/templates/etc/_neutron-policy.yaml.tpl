# Rule for cloud admin access
"context_is_admin": "rule:context_is_cloud_admin"

# Rule for resource owner access
"owner": "tenant_id:%(tenant_id)s or project_id:%(project_id)s"

# Rule for network owner access
"network_owner": "tenant_id:%(network:tenant_id)s"

# Rule of shared network
#"shared": "field:networks:shared=True"

# Default access rule
"default": "rule:context_is_editor or rule:shared"

# Definition of a shared address scope
#"shared_address_scopes": "field:address_scopes:shared=True"

# Create an address scope
# POST  /address-scopes
# Intended scope(s): project
"create_address_scope": "rule:context_is_admin"

# Create a shared address scope
# POST  /address-scopes
# Intended scope(s): project
"create_address_scope:shared": "rule:context_is_admin"

# Get an address scope
# GET  /address-scopes
# GET  /address-scopes/{id}
# Intended scope(s): project
"get_address_scope": "rule:context_is_editor or rule:shared_address_scopes"

# Update an address scope
# PUT  /address-scopes/{id}
# Intended scope(s): project
"update_address_scope": "rule:context_is_admin"

# Update ``shared`` attribute of an address scope
# PUT  /address-scopes/{id}
# Intended scope(s): project
"update_address_scope:shared": "rule:context_is_admin"

# Delete an address scope
# DELETE  /address-scopes/{id}
# Intended scope(s): project
"delete_address_scope": "rule:context_is_admin"

# Get an agent
# GET  /agents
# GET  /agents/{id}
# Intended scope(s): project
"get_agent": "rule:context_is_admin"

# Update an agent
# PUT  /agents/{id}
# Intended scope(s): project
"update_agent": "rule:context_is_admin"

# Delete an agent
# DELETE  /agents/{id}
# Intended scope(s): project
"delete_agent": "rule:context_is_admin"

# Add a network to a DHCP agent
# POST  /agents/{agent_id}/dhcp-networks
# Intended scope(s): project
"create_dhcp-network": "rule:context_is_admin"

# List networks on a DHCP agent
# GET  /agents/{agent_id}/dhcp-networks
# Intended scope(s): project
"get_dhcp-networks": "rule:context_is_admin"

# Remove a network from a DHCP agent
# DELETE  /agents/{agent_id}/dhcp-networks/{network_id}
# Intended scope(s): project
"delete_dhcp-network": "rule:context_is_admin"

# Add a router to an L3 agent
# POST  /agents/{agent_id}/l3-routers
# Intended scope(s): project
"create_l3-router": "rule:context_is_admin"

# List routers on an L3 agent
# GET  /agents/{agent_id}/l3-routers
# Intended scope(s): project
"get_l3-routers": "rule:context_is_admin"

# Remove a router from an L3 agent
# DELETE  /agents/{agent_id}/l3-routers/{router_id}
# Intended scope(s): project
"delete_l3-router": "rule:context_is_admin"

# List DHCP agents hosting a network
# GET  /networks/{network_id}/dhcp-agents
# Intended scope(s): project
"get_dhcp-agents": "rule:context_is_admin"

# List L3 agents hosting a router
# GET  /routers/{router_id}/l3-agents
# Intended scope(s): project
"get_l3-agents": "rule:context_is_admin"

# Get a project's auto-allocated topology
# GET  /auto-allocated-topology/{project_id}
# Intended scope(s): project
"get_auto_allocated_topology": "rule:context_is_network_admin"

# Create a flavor
# POST  /flavors
# Intended scope(s): project
"create_flavor": "rule:context_is_admin"

# Get a flavor
# GET  /flavors
# GET  /flavors/{id}
# Intended scope(s): project
"get_flavor": "rule:network_view_all"

# Update a flavor
# PUT  /flavors/{id}
# Intended scope(s): project
"update_flavor": "rule:context_is_admin"

# Delete a flavor
# DELETE  /flavors/{id}
# Intended scope(s): project
"delete_flavor": "rule:context_is_admin"

# Create a service profile
# POST  /service_profiles
# Intended scope(s): project
"create_service_profile": "rule:context_is_admin"

# Get a service profile
# GET  /service_profiles
# GET  /service_profiles/{id}
# Intended scope(s): project
"get_service_profile": "rule:network_view_all"

# Update a service profile
# PUT  /service_profiles/{id}
# Intended scope(s): project
"update_service_profile": "rule:context_is_admin"

# Delete a service profile
# DELETE  /service_profiles/{id}
# Intended scope(s): project
"delete_service_profile": "rule:context_is_admin"

# Get a flavor associated with a given service profiles. There is no
# corresponding GET operations in API currently. This rule is
# currently referred only in the DELETE of flavor_service_profile.
# Intended scope(s): project
"get_flavor_service_profile": "rule:network_view_all"

# Associate a flavor with a service profile
# POST  /flavors/{flavor_id}/service_profiles
# Intended scope(s): project
"create_flavor_service_profile": "rule:context_is_admin"

# Disassociate a flavor with a service profile
# DELETE  /flavors/{flavor_id}/service_profiles/{profile_id}
# Intended scope(s): project
"delete_flavor_service_profile": "rule:context_is_admin"

# Create a floating IP
# POST  /floatingips
# Intended scope(s): project
"create_floatingip": "rule:context_is_editor"

# Create a floating IP with a specific IP address
# POST  /floatingips
# Intended scope(s): project
"create_floatingip:floating_ip_address": "rule:context_is_network_admin"

# Get a floating IP
# GET  /floatingips
# GET  /floatingips/{id}
# Intended scope(s): project
"get_floatingip": "rule:context_is_viewer"

# Update a floating IP
# PUT  /floatingips/{id}
# Intended scope(s): project
"update_floatingip": "rule:context_is_editor"

# Delete a floating IP
# DELETE  /floatingips/{id}
# Intended scope(s): project
"delete_floatingip": "rule:context_is_editor"

# Create a network log
# POST  /log/logs
# Intended scope(s): project
"create_log": "rule:context_is_network_admin"

# Get a network log
# GET  /log/logs
# GET  /log/logs/{id}
# Intended scope(s): project
"get_log": "rule:context_is_network_viewer"

# Update a network log
# PUT  /log/logs/{id}
# Intended scope(s): project
"update_log": "rule:context_is_network_admin"

# Delete a network log
# DELETE  /log/logs/{id}
# Intended scope(s): project
"delete_log": "rule:context_is_network_admin"

# Create a metering label
# POST  /metering/metering-labels
# Intended scope(s): project
"create_metering_label": "rule:context_is_admin"

# Get a metering label
# GET  /metering/metering-labels
# GET  /metering/metering-labels/{id}
# Intended scope(s): project
"get_metering_label": "rule:context_is_admin"

# Delete a metering label
# DELETE  /metering/metering-labels/{id}
# Intended scope(s): project
"delete_metering_label": "rule:context_is_admin"

# Create a metering label rule
# POST  /metering/metering-label-rules
# Intended scope(s): project
"create_metering_label_rule": "rule:context_is_admin"

# Get a metering label rule
# GET  /metering/metering-label-rules
# GET  /metering/metering-label-rules/{id}
# Intended scope(s): project
"get_metering_label_rule": "rule:context_is_admin"

# Delete a metering label rule
# DELETE  /metering/metering-label-rules/{id}
# Intended scope(s): project
"delete_metering_label_rule": "rule:context_is_admin"

# Create a network
# POST  /networks
# Intended scope(s): project
"create_network": "rule:context_is_network_admin"

# Create a shared network
# POST  /networks
# Intended scope(s): project
"create_network:shared": "rule:context_is_admin"

# Create an external network
# POST  /networks
# Intended scope(s): project
"create_network:router:external": "rule:context_is_network_admin"

# Specify ``is_default`` attribute when creating a network
# POST  /networks
# Intended scope(s): project
"create_network:is_default": "rule:context_is_admin"

# Specify ``segments`` attribute when creating a network
# POST  /networks
# Intended scope(s): project
"create_network:segments": "rule:context_is_admin"

# Specify ``provider:network_type`` when creating a network
# POST  /networks
# Intended scope(s): project
"create_network:provider:network_type": "rule:context_is_admin"

# Specify ``provider:physical_network`` when creating a network
# POST  /networks
# Intended scope(s): project
"create_network:provider:physical_network": "rule:context_is_admin"

# Specify ``provider:segmentation_id`` when creating a network
# POST  /networks
# Intended scope(s): project
"create_network:provider:segmentation_id": "rule:context_is_admin"

# Get a network
# GET  /networks
# GET  /networks/{id}
# Intended scope(s): project
"get_network": "rule:default_viewer"

# Get ``segments`` attribute of a network
# GET  /networks
# GET  /networks/{id}
# Intended scope(s): project
"get_network:segments": "rule:default_viewer"

# Get ``provider:network_type`` attribute of a network
# GET  /networks
# GET  /networks/{id}
# Intended scope(s): project
"get_network:provider:network_type": "rule:default_viewer"

# Get ``provider:physical_network`` attribute of a network
# GET  /networks
# GET  /networks/{id}
# Intended scope(s): project
"get_network:provider:physical_network": "rule:default_viewer"

# Get ``provider:segmentation_id`` attribute of a network
# GET  /networks
# GET  /networks/{id}
# Intended scope(s): project
"get_network:provider:segmentation_id": "rule:default_viewer"

# Update a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network": "rule:context_is_network_admin"

# Update ``segments`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:segments": "rule:context_is_admin"

# Update ``shared`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:shared": "rule:context_is_admin"

# Update ``provider:network_type`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:provider:network_type": "rule:context_is_admin"

# Update ``provider:physical_network`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:provider:physical_network": "rule:context_is_admin"

# Update ``provider:segmentation_id`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:provider:segmentation_id": "rule:context_is_admin"

# Update ``router:external`` attribute of a network
# PUT  /networks/{id}
# Intended scope(s): project
"update_network:router:external": "rule:context_is_network_admin"

# Delete a network
# DELETE  /networks/{id}
# Intended scope(s): project
"delete_network": "rule:context_is_network_admin"

# Get network IP availability
# GET  /network-ip-availabilities
# GET  /network-ip-availabilities/{network_id}
# Intended scope(s): project
"get_network_ip_availability": "rule:default_network_viewer"

# Definition of port with network device_owner
#"network_device": "field:port:device_owner=~^network:"

# Create a port
# POST  /ports
# Intended scope(s): project
"create_port": "rule:default"

# Specify ``device_owner`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:device_owner": "(not rule:network_device and not rule:share_device) or rule:context_is_admin"

# Specify ``mac_address`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:mac_address": "rule:context_is_network_editor"

# Specify ``fixed_ips`` information when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:fixed_ips": "rule:default"

# Specify IP address in ``fixed_ips`` when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:fixed_ips:ip_address": "rule:default"

# Specify subnet ID in ``fixed_ips`` when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:fixed_ips:subnet_id": "rule:default"

# Specify ``port_security_enabled`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:port_security_enabled": "rule:context_is_network_editor"

# Specify ``binding:host_id`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:binding:host_id": "rule:context_is_network_admin"

# Specify ``binding:profile`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:binding:profile": "rule:context_is_network_admin"

# Specify ``binding:vnic_type`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:binding:vnic_type": "rule:context_is_network_admin"

# Specify ``allowed_address_pairs`` attribute when creating a port
# POST  /ports
# Intended scope(s): project
"create_port:allowed_address_pairs": "rule:context_is_network_editor"

# Specify ``ip_address`` of ``allowed_address_pairs`` attribute when
# creating a port
# POST  /ports
# Intended scope(s): project
"create_port:allowed_address_pairs:ip_address": "rule:context_is_network_editor"

# Get a port
# GET  /ports
# GET  /ports/{id}
# Intended scope(s): project
"get_port": "rule:context_is_network_viewer"

# Get ``binding:vif_type`` attribute of a port
# GET  /ports
# GET  /ports/{id}
# Intended scope(s): project
"get_port:binding:vif_type": "rule:context_is_network_viewer"

# Get ``binding:vif_details`` attribute of a port
# GET  /ports
# GET  /ports/{id}
# Intended scope(s): project
"get_port:binding:vif_details": "rule:context_is_network_viewer"

# Get ``binding:host_id`` attribute of a port
# GET  /ports
# GET  /ports/{id}
# Intended scope(s): project
"get_port:binding:host_id": "rule:context_is_network_viewer"

# Get ``binding:profile`` attribute of a port
# GET  /ports
# GET  /ports/{id}
# Intended scope(s): project
"get_port:binding:profile": "rule:context_is_network_viewer"

# Update a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port": "rule:context_is_editor or rule:context_is_securitygroup_admin"

# Update ``device_owner`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:device_owner": "(not rule:network_device and not rule:share_device) or rule:context_is_admin"

# Update ``mac_address`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:mac_address": "rule:context_is_admin"

# Specify ``fixed_ips`` information when updating a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:fixed_ips": "(rule:context_is_editor and not rule:network_device and not rule:share_device) or rule:context_is_admin"

# Specify IP address in ``fixed_ips`` information when updating a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:fixed_ips:ip_address": "(rule:context_is_editor and not rule:network_device and not rule:share_device) or rule:context_is_admin"

# Specify subnet ID in ``fixed_ips`` information when updating a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:fixed_ips:subnet_id": "(rule:context_is_editor and not rule:network_device and not rule:share_device) or rule:context_is_admin"

# Update ``port_security_enabled`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:port_security_enabled": "rule:context_is_network_editor"

# Update ``binding:host_id`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:binding:host_id": "rule:context_is_network_admin"

# Update ``binding:profile`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:binding:profile": "rule:context_is_network_admin"

# Update ``binding:vnic_type`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:binding:vnic_type": "rule:context_is_network_admin"

# Update ``allowed_address_pairs`` attribute of a port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:allowed_address_pairs": "rule:context_is_network_editor"

# Update ``ip_address`` of ``allowed_address_pairs`` attribute of a
# port
# PUT  /ports/{id}
# Intended scope(s): project
"update_port:allowed_address_pairs:ip_address": "rule:context_is_network_editor"

# Delete a port
# DELETE  /ports/{id}
# Intended scope(s): project
"delete_port": "(not rule:network_device and not rule:share_device and rule:context_is_network_editor) or rule:context_is_admin"

# Get QoS policies
# GET  /qos/policies
# GET  /qos/policies/{id}
# Intended scope(s): project
"get_policy": "rule:context_is_admin"

# Create a QoS policy
# POST  /qos/policies
# Intended scope(s): project
"create_policy": "rule:context_is_admin"

# Update a QoS policy
# PUT  /qos/policies/{id}
# Intended scope(s): project
"update_policy": "rule:context_is_admin"

# Delete a QoS policy
# DELETE  /qos/policies/{id}
# Intended scope(s): project
"delete_policy": "rule:context_is_admin"

# Get available QoS rule types
# GET  /qos/rule-types
# GET  /qos/rule-types/{rule_type}
# Intended scope(s): project
"get_rule_type": "rule:context_is_admin"

# Get a QoS bandwidth limit rule
# GET  /qos/policies/{policy_id}/bandwidth_limit_rules
# GET  /qos/policies/{policy_id}/bandwidth_limit_rules/{rule_id}
# Intended scope(s): project
"get_policy_bandwidth_limit_rule": "rule:context_is_admin"

# Create a QoS bandwidth limit rule
# POST  /qos/policies/{policy_id}/bandwidth_limit_rules
# Intended scope(s): project
"create_policy_bandwidth_limit_rule": "rule:context_is_admin"

# Update a QoS bandwidth limit rule
# PUT  /qos/policies/{policy_id}/bandwidth_limit_rules/{rule_id}
# Intended scope(s): project
"update_policy_bandwidth_limit_rule": "rule:context_is_admin"

# Delete a QoS bandwidth limit rule
# DELETE  /qos/policies/{policy_id}/bandwidth_limit_rules/{rule_id}
# Intended scope(s): project
"delete_policy_bandwidth_limit_rule": "rule:context_is_admin"

# Get a QoS DSCP marking rule
# GET  /qos/policies/{policy_id}/dscp_marking_rules
# GET  /qos/policies/{policy_id}/dscp_marking_rules/{rule_id}
# Intended scope(s): project
"get_policy_dscp_marking_rule": "rule:context_is_admin"

# Create a QoS DSCP marking rule
# POST  /qos/policies/{policy_id}/dscp_marking_rules
# Intended scope(s): project
"create_policy_dscp_marking_rule": "rule:context_is_admin"

# Update a QoS DSCP marking rule
# PUT  /qos/policies/{policy_id}/dscp_marking_rules/{rule_id}
# Intended scope(s): project
"update_policy_dscp_marking_rule": "rule:context_is_admin"

# Delete a QoS DSCP marking rule
# DELETE  /qos/policies/{policy_id}/dscp_marking_rules/{rule_id}
# Intended scope(s): project
"delete_policy_dscp_marking_rule": "rule:context_is_admin"

# Definition of a wildcard target_project
"restrict_wildcard": "(not field:rbac_policy:target_tenant=*) or rule:context_is_admin"

# Create an RBAC policy
# POST  /rbac-policies
# Intended scope(s): project
"create_rbac_policy": "rule:context_is_network_admin"

# Specify ``target_tenant`` when creating an RBAC policy
# POST  /rbac-policies
# Intended scope(s): project
"create_rbac_policy:target_tenant": "rule:restrict_wildcard"

# Update an RBAC policy
# PUT  /rbac-policies/{id}
# Intended scope(s): project
"update_rbac_policy": "rule:context_is_network_admin"

# Update ``target_tenant`` attribute of an RBAC policy
# PUT  /rbac-policies/{id}
# Intended scope(s): project
"update_rbac_policy:target_tenant": "rule:restrict_wildcard and rule:context_is_network_admin"

# Get an RBAC policy
# GET  /rbac-policies
# GET  /rbac-policies/{id}
# Intended scope(s): project
"get_rbac_policy": "rule:context_is_viewer"

# Delete an RBAC policy
# DELETE  /rbac-policies/{id}
# Intended scope(s): project
"delete_rbac_policy": "rule:context_is_network_admin"

# Create a router
# POST  /routers
# Intended scope(s): project
"create_router": "rule:context_is_network_admin"

# Specify ``distributed`` attribute when creating a router
# POST  /routers
# Intended scope(s): project
"create_router:distributed": "rule:context_is_admin"

# Specify ``ha`` attribute when creating a router
# POST  /routers
# Intended scope(s): project
"create_router:ha": "rule:context_is_admin"

# Specify ``enable_snat`` in ``external_gateway_info`` information
# when creating a router
# POST  /routers
# Intended scope(s): project
"create_router:external_gateway_info:enable_snat": "rule:context_is_admin"

# Specify ``external_fixed_ips`` in ``external_gateway_info``
# information when creating a router
# POST  /routers
# Intended scope(s): project
"create_router:external_gateway_info:external_fixed_ips": "rule:context_is_network_admin"

# Get a router
# GET  /routers
# GET  /routers/{id}
# Intended scope(s): project
"get_router": "rule:context_is_viewer"

# Get ``distributed`` attribute of a router
# GET  /routers
# GET  /routers/{id}
# Intended scope(s): project
"get_router:distributed": "rule:context_is_admin"

# Get ``ha`` attribute of a router
# GET  /routers
# GET  /routers/{id}
# Intended scope(s): project
"get_router:ha": "rule:context_is_admin"

# Update a router
# PUT  /routers/{id}
# Intended scope(s): project
"update_router": "rule:context_is_network_admin"

# Update ``distributed`` attribute of a router
# PUT  /routers/{id}
# Intended scope(s): project
"update_router:distributed": "rule:context_is_admin"

# Update ``ha`` attribute of a router
# PUT  /routers/{id}
# Intended scope(s): project
"update_router:ha": "rule:context_is_admin"

# Update ``enable_snat`` attribute of ``external_gateway_info``
# information of a router
# PUT  /routers/{id}
# Intended scope(s): project
"update_router:external_gateway_info:enable_snat": "rule:context_is_admin"

# Update ``external_fixed_ips`` attribute of ``external_gateway_info``
# information of a router
# PUT  /routers/{id}
# Intended scope(s): project
"update_router:external_gateway_info:external_fixed_ips": "rule:context_is_network_admin"

# Delete a router
# DELETE  /routers/{id}
# Intended scope(s): project
"delete_router": "rule:context_is_network_admin"

# Add an interface to a router
# PUT  /routers/{id}/add_router_interface
# Intended scope(s): project
"add_router_interface": "rule:context_is_editor"

# Remove an interface from a router
# PUT  /routers/{id}/remove_router_interface
# Intended scope(s): project
"remove_router_interface": "rule:context_is_editor"

# Create a security group
# POST  /security-groups
# Intended scope(s): project
"create_security_group": "rule:context_is_securitygroup_admin"

# Get a security group
# GET  /security-groups
# GET  /security-groups/{id}
# Intended scope(s): project
"get_security_group": "rule:context_is_securitygroup_viewer or rule:shared_security_groups"

# Update a security group
# PUT  /security-groups/{id}
# Intended scope(s): project
"update_security_group": "rule:context_is_securitygroup_admin"

# Delete a security group
# DELETE  /security-groups/{id}
# Intended scope(s): project
"delete_security_group": "rule:context_is_securitygroup_admin"

# Create a security group rule
# POST  /security-group-rules
# Intended scope(s): project
"create_security_group_rule": "rule:context_is_securitygroup_admin"

# Get a security group rule
# GET  /security-group-rules
# GET  /security-group-rules/{id}
# Intended scope(s): project
"get_security_group_rule": "rule:context_is_securitygroup_viewer"

# Delete a security group rule
# DELETE  /security-group-rules/{id}
# Intended scope(s): project
"delete_security_group_rule": "rule:context_is_securitygroup_admin"

# Create a segment
# POST  /segments
# Intended scope(s): project
"create_segment": "rule:context_is_admin"

# Get a segment
# GET  /segments
# GET  /segments/{id}
# Intended scope(s): project
"get_segment": "rule:context_is_admin"

# Get the segment tags
# GET  /segments/{id}/tags
# GET  /segments/{id}/tags/{tag_id}
# Intended scope(s): project
"get_segments_tags": "rule:context_is_admin"

# Update a segment
# PUT  /segments/{id}
# Intended scope(s): project
"update_segment": "rule:context_is_admin"

# Update the segment tags
# PUT  /segments/{id}/tags
# PUT  /segments/{id}/tags/{tag_id}
# Intended scope(s): project
"update_segments_tags": "rule:context_is_admin"

# Delete a segment
# DELETE  /segments/{id}
# Intended scope(s): project
"delete_segment": "rule:context_is_admin"

# Delete the segment tags
# DELETE  /segments/{id}/tags
# DELETE  /segments/{id}/tags/{tag_id}
# Intended scope(s): project
"delete_segments_tags": "rule:context_is_admin"

# Get service providers
# GET  /service-providers
# Intended scope(s): project
"get_service_provider": "rule:context_is_admin"

# Create a subnet
# POST  /subnets
# Intended scope(s): project
"create_subnet": "rule:context_is_admin or (rule:network_admin and rule:network_owner)"

# Specify ``segment_id`` attribute when creating a subnet
# POST  /subnets
# Intended scope(s): project
"create_subnet:segment_id": "rule:context_is_admin"

# Get a subnet
# GET  /subnets
# GET  /subnets/{id}
# Intended scope(s): project
"get_subnet": "rule:default_viewer"

# Get ``segment_id`` attribute of a subnet
# GET  /subnets
# GET  /subnets/{id}
# Intended scope(s): project
"get_subnet:segment_id": "rule:default_viewer"

# Update a subnet
# PUT  /subnets/{id}
# Intended scope(s): project
"update_subnet": "rule:context_is_network_admin"

# Delete a subnet
# DELETE  /subnets/{id}
# Intended scope(s): project
"delete_subnet": "rule:context_is_network_admin"

# Definition of a shared subnetpool
#"shared_subnetpools": "field:subnetpools:shared=True"

# Create a subnetpool
# POST  /subnetpools
# Intended scope(s): project
"create_subnetpool": "rule:context_is_network_admin"

# Create a shared subnetpool
# POST  /subnetpools
# Intended scope(s): project
"create_subnetpool:shared": "rule:context_is_admin"

# Specify ``is_default`` attribute when creating a subnetpool
# POST  /subnetpools
# Intended scope(s): project
"create_subnetpool:is_default": "rule:context_is_admin"

# Get a subnetpool
# GET  /subnetpools
# GET  /subnetpools/{id}
# Intended scope(s): project
"get_subnetpool": "rule:context_is_viewer or rule:shared_subnetpools"

# Update a subnetpool
# PUT  /subnetpools/{id}
# Intended scope(s): project
"update_subnetpool": "rule:context_is_network_admin"

# Update ``is_default`` attribute of a subnetpool
# PUT  /subnetpools/{id}
# Intended scope(s): project
"update_subnetpool:is_default": "rule:context_is_admin"

# Delete a subnetpool
# DELETE  /subnetpools/{id}
# Intended scope(s): project
"delete_subnetpool": "rule:context_is_network_admin"

# Create a trunk
# POST  /trunks
# Intended scope(s): project
"create_trunk": "rule:context_is_network_admin"

# Get a trunk
# GET  /trunks
# GET  /trunks/{id}
# Intended scope(s): project
"get_trunk": "rule:context_is_network_viewer"

# Delete a trunk
# DELETE  /trunks/{id}
# Intended scope(s): project
"delete_trunk": "rule:context_is_network_admin"

# List subports attached to a trunk
# GET  /trunks/{id}/get_subports
# Intended scope(s): project
"get_subports": "rule:context_is_network_viewer"

# Add subports to a trunk
# PUT  /trunks/{id}/add_subports
# Intended scope(s): project
"add_subports": "rule:context_is_network_admin"

# Delete subports from a trunk
# PUT  /trunks/{id}/remove_subports
# Intended scope(s): project
"remove_subports": "rule:context_is_network_admin"

# =============================================================================
# WARNING: Below rules are either deprecated rules or extra rules in the policy
# file. It is strongly recommended to switch to the new upstream rules.
#
# For readability these "extra" rules have been grouped into sections below.
# The grouping and blank lines are purely cosmetic - keys and values are
# unchanged, so oslo.policy loads this identically to the flat version.
# =============================================================================


# -----------------------------------------------------------------------------
# Custom RBAC layer (SAP/SDC roles)
#
# Not part of upstream Neutron. Defines our own role aliases and the
# context_is_* / network_* / securitygroup_* rule hierarchy that every
# resource rule below ultimately references.
# -----------------------------------------------------------------------------
"context_is_cloud_admin": "role:cloud_network_admin"
"member": "role:member and rule:owner"
"viewer": "role:network_viewer and rule:owner"
"admin": "role:network_admin and rule:owner"
"compute_admin_wsg": "role:compute_admin_wsg and rule:owner"
"context_is_network_admin": "rule:context_is_admin or rule:admin"
"context_is_editor": "rule:context_is_network_admin or rule:member or rule:compute_admin_wsg"
"context_is_viewer": "rule:context_is_editor or rule:viewer"
"network_view_all": "role:network_viewer or role:member or role:network_admin or rule:context_is_admin"
"network_owner_or_owner": "rule:owner or rule:network_owner"
"network_member": "role:member and rule:network_owner_or_owner"
"network_viewer": "role:network_viewer and rule:network_owner_or_owner"
"network_admin": "role:network_admin and rule:network_owner_or_owner"
"context_is_network_network_admin": "rule:context_is_admin or rule:network_admin"
"context_is_network_editor": "rule:context_is_network_network_admin or rule:network_member"
"context_is_network_viewer": "rule:context_is_network_editor or rule:network_viewer"
"compute_admin": "role:compute_admin and rule:owner"
"context_is_compute_admin": "role:cloud_compute_admin or rule:compute_admin"
"context_is_securitygroup_admin": "(role:securitygroup_admin and rule:owner) or rule:context_is_compute_admin or rule:context_is_network_admin"
"context_is_securitygroup_viewer": "(role:securitygroup_viewer and rule:owner) or rule:context_is_viewer or rule:context_is_securitygroup_admin"


# -----------------------------------------------------------------------------
# Shared / helper field rules and default viewers
#
# "field:*:shared=True" style helpers plus the default_viewer aliases used by
# many of the GET rules.
# -----------------------------------------------------------------------------
"shared_firewalls": "field:firewalls:shared=True"
"shared_firewall_policies": "field:firewall_policies:shared=True"
"shared_security_groups": "field:security_groups:shared=True"
"shared_bgpvpns": "field:bgpvpns:shared=True"
"dhcp_enabled": "field:subnets:enable_dhcp=True"
"default_viewer": "rule:context_is_viewer or rule:shared"
"default_network_viewer": "rule:context_is_network_viewer or rule:shared"


# -----------------------------------------------------------------------------
# Subnet / subnetpool rules
# -----------------------------------------------------------------------------
"get_subnets_tags": "rule:default_viewer"
"update_subnets_tags": "rule:context_is_network_admin"
"delete_subnets_tags": "rule:context_is_network_admin"
"create_subnetpool:address_scope_id": "rule:context_is_admin"
"get_subnetpools_tags": "rule:context_is_viewer or rule:shared_subnetpools"
"update_subnetpools_tags": "rule:context_is_network_admin"
"update_subnetpool:address_scope_id": "rule:context_is_admin"
"delete_subnetpools_tags": "rule:context_is_network_admin"


# -----------------------------------------------------------------------------
# Network rules (tags, segment ranges, legacy attributes)
# -----------------------------------------------------------------------------
"get_network:router:external": "rule:default_viewer"
"get_network:queue_id": "rule:context_is_admin"
"get_network_ip_availabilities": "rule:default_network_viewer"
"get_networks_tags": "rule:default_viewer"
"get_network_segment_ranges_tags": "rule:default_viewer"
"update_networks_tags": "rule:context_is_network_admin"
"update_network_segment_ranges_tags": "rule:context_is_network_admin"
"delete_networks_tags": "rule:context_is_network_admin"
"delete_network_segment_ranges_tags": "rule:context_is_network_admin"


# -----------------------------------------------------------------------------
# Port rules (tags, mac_learning, legacy attributes)
# -----------------------------------------------------------------------------
"share_device": "field:port:device_owner=~^manila:"
"create_port:mac_learning_enabled": "rule:context_is_network_editor"
"get_port:queue_id": "rule:context_is_admin"
"get_port:binding:vnic_type": "rule:context_is_network_viewer"
"get_ports_tags": "rule:context_is_network_viewer"
"update_port:security_groups": "rule:context_is_editor or rule:context_is_securitygroup_admin"
"update_port:mac_learning_enabled": "rule:context_is_network_editor"
"update_ports_tags": "rule:context_is_network_admin"
"delete_ports_tags": "(not rule:network_device and not rule:share_device and rule:context_is_network_editor) or rule:context_is_admin"


# -----------------------------------------------------------------------------
# Router rules (tags, Cisco HA extension)
# -----------------------------------------------------------------------------
"get_routers_tags": "rule:context_is_viewer"
"update_routers_tags": "rule:context_is_network_admin"
"update_router:cisco_ha:enabled": "rule:context_is_admin"
"update_router:cisco_ha:details": "rule:context_is_admin"
"delete_routers_tags": "rule:context_is_network_admin"


# -----------------------------------------------------------------------------
# Security group rules (tags, stateful, bulk list)
# -----------------------------------------------------------------------------
"get_security_groups": "rule:context_is_securitygroup_viewer or rule:shared_security_groups"
"get_security_groups_tags": "rule:context_is_securitygroup_viewer or rule:shared_security_groups"
"update_security_group:stateful": "rule:context_is_admin"
"update_security_groups_tags": "rule:context_is_securitygroup_admin"
"delete_security_groups_tags": "rule:context_is_securitygroup_admin"
"get_security_group_rules": "rule:context_is_securitygroup_viewer"
"update_security_group_rule": "rule:context_is_securitygroup_admin"


# -----------------------------------------------------------------------------
# FWaaS (Firewall-as-a-Service): groups, policies and rules
#
# Stadium project, not in core Neutron defaults.
# -----------------------------------------------------------------------------
"create_firewall_group": "rule:context_is_network_admin"
"update_firewall_group": "rule:context_is_network_admin"
"delete_firewall_group": "rule:context_is_network_admin"
"create_firewall_group:shared": "rule:context_is_network_admin"
"update_firewall_group:shared": "rule:context_is_network_admin"
"delete_firewall_group:shared": "rule:context_is_network_admin"
"get_firewall_group": "rule:context_is_viewer or rule:shared_firewall_policies"
"create_firewall_policy": "rule:context_is_network_admin"
"get_firewall_policy": "rule:context_is_viewer or rule:shared_firewall_policies"
"create_firewall_policy:shared": "rule:context_is_network_admin"
"update_firewall_policy": "rule:context_is_network_admin"
"delete_firewall_policy": "rule:context_is_network_admin"
"insert_rule": "rule:context_is_network_admin"
"remove_rule": "rule:context_is_network_admin"
"create_firewall_rule": "rule:context_is_network_admin"
"get_firewall_rule": "rule:context_is_viewer or rule:shared_firewalls"
"update_firewall_rule": "rule:context_is_network_admin"
"delete_firewall_rule": "rule:context_is_network_admin"


# -----------------------------------------------------------------------------
# Legacy / removed extensions (QoS queues, LBaaS v1 agents, LSN,
# network/policy profiles)
# -----------------------------------------------------------------------------
"create_qos_queue": "rule:context_is_admin"
"get_qos_queue": "rule:context_is_admin"
"get_loadbalancer-agent": "rule:context_is_admin"
"get_loadbalancer-pools": "rule:context_is_admin"
"get_agent-loadbalancers": "rule:context_is_admin"
"get_loadbalancer-hosting-agent": "rule:context_is_admin"
"create_network_profile": "rule:context_is_admin"
"update_network_profile": "rule:context_is_admin"
"delete_network_profile": "rule:context_is_admin"
"get_network_profiles": "rule:context_is_admin"
"get_network_profile": "rule:context_is_admin"
"update_policy_profiles": "rule:context_is_admin"
"get_policy_profiles": "rule:context_is_admin"
"get_policy_profile": "rule:context_is_admin"
"get_lsn": "rule:context_is_admin"
"create_lsn": "rule:context_is_admin"


# -----------------------------------------------------------------------------
# Floating IP / flavor / service profile / trunk / logging tags
# -----------------------------------------------------------------------------
"update_floatingips_tags": "rule:context_is_editor"
"delete_floatingips_tags": "rule:context_is_editor"
"get_floatingips_tags": "rule:context_is_viewer"
"get_flavors": "rule:network_view_all"
"get_service_profiles": "rule:network_view_all"
"get_trunks_tags": "rule:context_is_network_viewer"
"delete_trunks_tags": "rule:context_is_network_admin"
"update_trunks_tags": "rule:context_is_network_admin"
"get_loggable_resources": "rule:network_view_all"
"get_logs": "rule:context_is_network_viewer"


# -----------------------------------------------------------------------------
# Interconnection (inter-network interconnections)
#
# Only emitted when the networking-interconnection extension is enabled.
# -----------------------------------------------------------------------------
{{- if .Values.interconnection.enabled }}
"create_interconnection": "rule:context_is_editor"
"update_interconnection": "rule:context_is_editor"
"update_interconnection:name": "rule:context_is_editor"
"update_interconnection:state": "rule:context_is_admin"
"update_interconnection:remote_interconnection_id": "rule:context_is_admin"
"delete_interconnection": "rule:context_is_editor"
"get_interconnection": "rule:context_is_editor"
{{- end }}


# -----------------------------------------------------------------------------
# BGPVPN: base resource + attributes
#
# Stadium project (networking-bgpvpn), not in core Neutron defaults.
# create_bgpvpn / delete_bgpvpn are relaxed to allow editors when any
# route-target auto-allocation is enabled, otherwise admin-only.
# -----------------------------------------------------------------------------
{{- if or (.Values.bgp_vpn.import_target_auto_allocation) (.Values.bgp_vpn.export_target_auto_allocation) (.Values.bgp_vpn.route_target_auto_allocation) }}
"create_bgpvpn": "rule:context_is_editor or rule:context_is_admin"
{{- else }}
"create_bgpvpn": "rule:context_is_admin"
{{- end }}
"update_bgpvpn": "rule:context_is_admin"
{{- if or (.Values.bgp_vpn.import_target_auto_allocation) (.Values.bgp_vpn.export_target_auto_allocation) (.Values.bgp_vpn.route_target_auto_allocation) }}
"delete_bgpvpn": "rule:context_is_editor or rule:context_is_admin"
{{- else }}
"delete_bgpvpn": "rule:context_is_admin"
{{- end }}
"get_bgpvpn": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:tenant_id": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:route_targets": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:import_targets": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:export_targets": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:route_distinguishers": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn:vni": "rule:context_is_viewer or rule:shared_bgpvpns"
"create_bgpvpn:route_targets": "rule:context_is_admin"
"create_bgpvpn:import_targets": "rule:context_is_admin"
"create_bgpvpn:export_targets": "rule:context_is_admin"
"create_bgpvpn:route_distinguishers": "rule:context_is_admin"
"create_bgpvpn:type": "rule:context_is_admin"
"create_bgpvpn:local_pref": "rule:context_is_admin"
"create_bgpvpn:vni": "rule:context_is_admin"
"update_bgpvpn:tenant_id": "rule:context_is_admin"
"update_bgpvpn:route_targets": "rule:context_is_admin"
"update_bgpvpn:import_targets": "rule:context_is_admin"
"update_bgpvpn:export_targets": "rule:context_is_admin"
"update_bgpvpn:route_distinguishers": "rule:context_is_admin"
"update_bgpvpn:vni": "rule:context_is_admin"

# BGPVPN: network associations
"create_bgpvpn_network_association": "rule:context_is_admin"
"update_bgpvpn_network_association": "rule:context_is_admin"
"delete_bgpvpn_network_association": "rule:context_is_admin"
"get_bgpvpn_network_association": "rule:context_is_admin"
"get_bgpvpn_network_association:tenant_id": "rule:context_is_admin"

# BGPVPN: port associations
"create_bgpvpn_port_association": "rule:context_is_admin"
"update_bgpvpn_port_association": "rule:context_is_admin"
"delete_bgpvpn_port_association": "rule:context_is_admin"
"get_bgpvpn_port_association": "rule:context_is_admin"
"get_bgpvpn_port_association:tenant_id": "rule:context_is_admin"

# BGPVPN: router associations
"create_bgpvpn_router_association": "rule:context_is_editor or rule:shared_bgpvpns"
"update_bgpvpn_router_association": "rule:context_is_editor or rule:shared_bgpvpns"
"delete_bgpvpn_router_association": "rule:context_is_editor or rule:shared_bgpvpns"
"get_bgpvpn_router_association": "rule:context_is_viewer or rule:shared_bgpvpns"
"get_bgpvpn_router_association:tenant_id": "rule:context_is_viewer or rule:shared_bgpvpns"
