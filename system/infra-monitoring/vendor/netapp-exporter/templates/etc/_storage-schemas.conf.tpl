[carbon]
pattern = ^carbon\.
retentions = 60:90d

[netapp.perf.dev]
pattern = ^netapp\.perf\.dev\..*
retentions = 10s:24h, 1m:100d, 15m:395d, 1h:5y

[netapp.poller.perf.dev]
pattern = ^netapp\.poller\.perf\.dev\..*
retentions = 10s:24h, 1m:100d, 15m:395d, 1h:5y

[netapp.perf7.dev]
pattern = ^netapp\.perf7\.dev\..*
retentions = 10s:24h, 1m:100d, 15m:395d, 1h:5y

[netapp.poller.perf7.dev]
pattern = ^netapp\.poller\.perf7\.dev\..*
retentions = 10s:24h, 1m:100d, 15m:395d, 1h:5y

[OPM]
pattern = ^netapp-performance\..*
retentions = 5m:100d, 15m:395d, 1h:5y

[OPM Capacity]
pattern = ^netapp-capacity\..*
retentions = 5m:100d, 1h:5y

[OPM Capacity Poller]
pattern = ^netapp-poller\..*
retentions = 5m:100d, 1h:5y

[netapp.capacity]
pattern = ^netapp\.capacity\.*
retentions = 15m:100d, 1d:5y

[netapp.poller.capacity]
pattern = ^netapp\.poller\.capacity\.*
retentions = 15m:100d, 1d:5y

[netapp.perf]
pattern = ^netapp\.perf\.*
retentions = 60s:35d, 5m:100d, 15m:395d, 1h:5y

[netapp.poller.perf]
pattern = ^netapp\.poller\.perf\.*
retentions = 60s:35d, 5m:100d, 15m:395d, 1h:5y

[netapp.perf7]
pattern = ^netapp\.perf7\.*
retentions = 60s:35d, 5m:100d, 15m:395d, 1h:5y

[netapp.poller.perf7]
pattern = ^netapp\.poller\.perf7\.*
retentions = 60s:35d, 5m:100d, 15m:395d, 1h:5y

[defaults]
pattern = .*
retentions = 60s:35d, 5m:100d, 15m:395d, 1h:5y