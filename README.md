# SAP Converged Charts

This repository contains Helm charts required by SAP Converged Cloud. 

## Structure

Charts are grouped logically into:

  * `common`: Reusable charts
  * `global`: Singletons that only exist once in a global context
  * `openstack`: Openstack and dependent or related services
  * `prometheus-exporters`: A curated collection of Prometheus exporters
  * `prometheus-rules`: Prometheus alert- & aggregation rules specific to our controlplane
  * `system`: Infrastructure required by the control plane 

This structure is just a logical grouping, it does not represent deployable
units or imply other semantics. 

## Charts 

On the second level we expect a chart. This can be a single chart or
a meta-chart that describe a dependent set of compononents. Meta-charts contain
sub-charts or reference charts from other repositories using Helm dependencies.

```
.
└── system
    ├── dns
    │   └── charts
    │       ├── bind
    │       └── unbound
    ├── kube-system
    │   └── charts
    │       ├── ingress
    │       └── dashboard
    └── prometheus
        └── charts
            ├── kube-state-metrics
            ├── prometheus-collector
            └── prometheus-frontend
```

We imply that the highest chart will be deployed as a Helm release. In this
example, releasing `dns` will install/update `bind` and `unbound`.

In order to be able to relate charts to running Kubernetes pods, we also imply
that a chart will be deployed in a namespace with the same name.  

```
$ kubectl get pods --all-namespaces                                                                                                                 0 ↵
NAMESPACE         NAME                                               READY     STATUS    RESTARTS   AGE
dns               bind1-2290429089-joidj                             2/2       Running   0          5d
dns               bind2-3590597799-1vcv0                             2/2       Running   0          5d
dns               unbound1-3007389427-shh2y                          1/1       Running   0          9d
dns               unbound1-3577488147-ld1rd                          1/1       Running   0          5d
kube-system       ingress-controller-d3snv                           1/1       Running   4          13d
kube-system       ingress-controller-j9bpf                           1/1       Running   2          18d
```

This has the benefits that:
 
  * Values required for releasing a chart can be found at the same place in `cc/regions`
  * Cleanup of a failed release, is as easy as deleting the namespace.
  * For testing a chart can deployed in a seperate testing namespace.
  * Pods and other Kubernetes primitives are reflected at a known place in
      Kubernetes

### Test a Chart

Opening a PR to this repository triggers the Helm chart tests which are described in detail [here](./ci/README.md).  

### Install/Update of a Chart/Release 

Per convention we use the name of the meta-chart as namespace and name of the
release. Values are pulled in from a secret repository.

```
helm upgrade dns ./system/dns --namespace dns --values ../secrets/staging/system/dns.yaml --install 
```
