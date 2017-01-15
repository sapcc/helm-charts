Api:
  # To configure Keystone correctly, a project-scoped token must be acquired.
  # To accomplish this, the configuration must be set up with one of the
  # following scenarios:
  #   Set username and password and you have a default project set in keystone.
  #   Set username, password and project id.
  #   Set username, password, project name and (domain id or domain name).
  #
  # Monitoring API URL: URL for the monitoring API, if undefined it will be pulled from the keystone service catalog
  # Example: https://region-a.geo-1.monitoring.hpcloudsvc.com:8080/v2.0
  url: {{.Values.monasca_api_endpoint_protocol_internal}}://{{.Values.monasca_api_endpoint_host_internal}}:{{.Values.monasca_api_port_internal}}/v2.0
  # Keystone Username
  username: {{.Values.monasca_agent_username}}
  # Keystone Password
  password: "{{.Values.monasca_agent_password}}"
  # Keystone API URL: URL for the Keystone server to use
  # Example: https://region-a.geo-1.identity.hpcloudsvc.com:35357/v3/
  keystone_url: {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
  # Domain name to be used to resolve username
  user_domain_name: {{.Values.monasca_agent_user_domain_name}}
  # Project name to be used by this agent
  project_name: {{.Values.monasca_admin_project_name}}
  # Project domain id to be used by this agent
  project_domain_name: {{.Values.monasca_admin_project_domain_name}}
  # Set whether certificates are used for Keystone
  # *******************************************************************************************
  # **** CAUTION ****: The insecure flag should NOT be set to True in a production environment!
  # *******************************************************************************************
  # If insecure is set to False, a ca_file name must be set to authenticate with Keystone
  insecure: False
  # Name of the ca certs file
  ca_file: {args.ca_file}

  # The following 2 options are for handling buffering and reconnection to the monasca-api
  # If you want the messages to be sent as fast as possible, set these two options to
  # the same number.  If you have a larger system with many agents, you may want to throttle
  # the number of messages sent to the API by setting the backlog_send_rate to a lower number.

  # Maximum number of messages to buffer when unable to communicate with the monasca-api
  max_buffer_size: 1000
  # Maximum number of messages to send at one time when communication with the monasca-api is restored
  backlog_send_rate: 1000

  # Publish extra metrics to the API by adding this number of 'amplifier' dimensions.
  # For load testing purposes only; set to 0 for production use.
  amplifier: 0

Main:
  # Force the hostname to whatever you want.
  hostname: {hostname}

  # Optional dimensions to be sent with every metric from this node
  # They should be in the format name: value
  # Example of dimensions below
  # dimensions:
  #   service: nova
  #   group: group_a
  #   environment: production
  dimensions:
    service: {service}
    component: {component}
    kubernetes.container_name: {kube_container_name}
    kubernetes.pod_name: {kube_pod_name}

  # Set the threshold for accepting points to allow anything
  # with recent_point_threshold seconds
  # Defaults to 30 seconds if no value is provided
  #recent_point_threshold: 30

  # time to wait between collection runs
  check_freq: 60

  # Threshold value for warning on collection time of each check (in seconds)
  sub_collection_warn: 6

  # Collector restart interval (in hours)
  collector_restart_interval: 24

  # Change port the Agent is listening to
  listen_port: {{.Values.monasca_agent_port_forwarder}}

  # Allow non-local traffic to this Agent
  # This is required when using this Agent as a proxy for other Agents
  # that might not have an internet connection
  # For more information, please see
  # https://github.com/DataDog/dd-agent/wiki/Network-Traffic-and-Proxy-Configuration
  # non_local_traffic: no

Statsd:
  # ========================================================================== #
  # Monasca Statsd configuration                                                    #
  # ========================================================================== #
  # Monasca Statsd is a small server that aggregates your custom app metrics.

  #  Make sure your client is sending to the same port.
  monasca_statsd_port: {{.Values.monasca_agent_port_statsd}}

  ## The monasca_statsd flush period.
  monasca_statsd_interval: 60

  # If you want to forward every packet received by the monasca_statsd server
  # to another statsd server, uncomment these lines.
  # WARNING: Make sure that forwarded packets are regular statsd packets and not "monasca_statsd" packets,
  # as your other statsd server might not be able to handle them.
  # IDEA: we could use these for prometheus forwarding
  # monasca_statsd_forward_host: localhost
  # monasca_statsd_statsd_forward_port: 8125

Logging:
  # ========================================================================== #
  # Logging
  # ========================================================================== #
  log_level: {{.Values.monasca_agent_loglevel}}
  disable_file_logging: True
  #collector_log_file: /var/log/monasca/agent/collector.log
  #forwarder_log_file: /var/log/monasca/agent/forwarder.log
  #statsd_log_file: /var/log/monasca/agent/statsd.log

  # if syslog is enabled but a host and port are not set, a local domain socket
  # connection will be attempted
  #
  # log_to_syslog: yes
  # syslog_host:
  # syslog_port:

