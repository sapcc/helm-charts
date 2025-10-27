# Vertical Pod Autoscaler (VPA)

Helm chart for the [vertical pod autoscaler (VPA)](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler),
which currently only provides kustomize resources for installation.

## Pre-requisites:

1) **Cert manager**: The admission webhook uses resources of the [jetstack/cert-manager](https://github.com/jetstack/cert-manager) to generate a self-signed certificate.

   
2) **Metrics API**: The recommender compute resource recommendations based on metrics fetched from the [metrics API](https://github.com/kubernetes/metrics) for which 
multiple implementations are available: [metrics-server](https://github.com/kubernetes-sigs/metrics-server), [prometheus-adapter](https://github.com/kubernetes-sigs/prometheus-adapter).

## Components

The VPA consists of 3 components:
1) **Recommender**:  
   Generates resource recommendations for VPAs and stores them in the status.
   See [documentation](https://github.com/kubernetes/autoscaler/blob/d872ec3db85de83acce44a8cde503dcb59014e54/vertical-pod-autoscaler/pkg/recommender/README.md).
   

2) **Updater**:  
   **WARNING**: For VPA instances with `mode: Auto`, pods may be evicted and re-created if the updater is enabled.  
   Kubernetes controller updating resource requirements on pods for which a VPA exists. 
   See [documentation](https://github.com/kubernetes/autoscaler/blob/d872ec3db85de83acce44a8cde503dcb59014e54/vertical-pod-autoscaler/pkg/updater/README.md).
   

3) **Admission webhook**:   
   For VPA instances with `mode: Initial|Auto` the mutating webhook updates resource requirements on pods during their creation.  
   See [documentation](https://github.com/kubernetes/autoscaler/blob/d872ec3db85de83acce44a8cde503dcb59014e54/vertical-pod-autoscaler/pkg/admission-controller/README.md).
