Prometheus Operator CRDs
------------------------

This Helm Chart contains the CRDs used by Calico.

## NOTE

Use `./get-crds <version>` to update the CRDs from the upstream repository.

## RBAC

Check if RBAC needs to be updated in `calico` and `calico-apiserver` charts. Files to compare:
- https://github.com/projectcalico/calico/blob/master/manifests/apiserver.yaml
- https://github.com/projectcalico/calico/blob/master/manifests/calico-typha.yaml
- https://github.com/projectcalico/calico/blob/master/manifests/calico.yaml
