Prometheus Operator CRDs
------------------------

This Helm Chart contains the CRDs used by the Rook Operator.

## NOTE

Use `./get-crds <version>` to update the CRDs from the upstream repository.

As per rook helm chart [crds](https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph/values.yaml#L14C1-L21) guidance, we can manually fertch crds from [examples](https://github.com/rook/rook/blob/master/deploy/examples/crds.yaml) of the respective release tag.
