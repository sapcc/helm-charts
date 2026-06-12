> **⚠ DEPRECATED** — This Helm chart is superseded by the kustomize-based
> deployment at
> [`system/kustomize/metal-operator-remote/`](../kustomize/metal-operator-remote/README.md).
>
> New deployments and per-cluster overlays should use the kustomize tree,
> which replaces the previous Helm/ManagedResource pipeline with two direct
> `kubectl apply -k` invocations (one per cluster: host + remote).
>
> This chart remains in the repository during the transition period and will
> be deleted in a follow-up change once all clusters have been migrated.
> See `system/kustomize/metal-operator-remote/README.md` for the current
> deployment model.

# metal-operator-remote (Helm chart — deprecated)

Helm chart for deploying the metal-operator in a split host/remote cluster
setup. Previously used Gardener's `ManagedResource` + `Secret` wrapping to
deliver remote-cluster resources. Replaced by the dual-kustomize approach in
`system/kustomize/metal-operator-remote/`.
