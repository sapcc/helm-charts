Calico CNI templates
------------------------

This Helm Chart contains Calico templates.

Review this chart before upgrading Calico version.

## RBAC

Check if RBAC needs to be updated in `calico` and `calico-apiserver` charts. Files to compare:
- https://github.com/projectcalico/calico/blob/master/manifests/apiserver.yaml
- https://github.com/projectcalico/calico/blob/master/manifests/calico-typha.yaml
- https://github.com/projectcalico/calico/blob/master/manifests/calico.yaml
