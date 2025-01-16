service_type: 'compute/baremetal'
service_name: 'ironic'
prefix: '/v1'

resources:
  allocations:
  chassis:
  deploy_templates:
  nodes:
    custom_id: id
    children:
      allocation:
      validate:
      maintenance:
      management:
      states:
        children:
          power:
      traits:
      vifs:
      vmedia:
  ports:
  portgroups:
  runbooks:
  volumes:
    children:
      connectors:
      targets:

