main:
    host: '{{.Values.vcenter_exporter.host}}'
    user: '{{.Values.vcenter_exporter.user}}'
    password: '{{.Values.vcenter_exporter.password}}'
    port: {{.Values.vcenter_exporter.port}}
    ignore_ssl: {{.Values.vcenter_exporter.ignore_ssl}}
#    vm_metrics:
#    - 'cpu.usage.average'
#    - 'cpu.usagemhz.average'
#    - 'cpu.ready.summation'
#    - 'mem.usage.average'
#    - 'mem.swapinRate.average'
#    - 'mem.swapoutRate.average'
#    - 'mem.vmmemctl.average'
#    - 'mem.consumed.average'
#    - 'mem.overhead.average'
#    - 'disk.usage.average'
