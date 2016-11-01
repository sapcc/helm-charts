# SAP Converged Charts

This repository contains Helm charts required by SAP Converged Cloud. It is
split into two parts:

  # Regional 
  # Reusable 

## Regional Charts

The subfolder `region` contains Helm charts that describe a whole region. They
are reused and parameterized per region.

The structure should be two charts deep. On the first level we expect charts
that logically group a set of applications. These charts correspond to
Kubernetes namespaces. For example:


```
.
└── region
    └── automation
    └── kube-system
    └── monitoring
    └── openstack
```

These logical meta-charts can contain sub-charts or reference charts from other
repositories using Helm dependencies. They should not contain a deeper
structure of charts.

```
.
└── region
    └── automation
        └── charts
            ├── arc
            └── lyra
```

## Reusable Charts

The subfolder `shared` contains charts that are not specific to Converged
Cloud. They can be reused and referenced in other projects.





