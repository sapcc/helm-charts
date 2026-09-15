# common/gatekeeper-policies

This chart does not deploy any objects by itself, but serves as a repository
for the declaration, implementation and testcases of Gatekeeper policies.

# To add a new policy

- Choose a name of the form `GkSomePolicyName` (see `files/policies` for the names of existing policies).
- Add the Rego code for the policy in `files/policies/$NAME.rego`.
- If the policy needs parameters, add the OpenAPI schema declaration and a set of test values in `files/parameters/$NAME.yaml`.
- To be able to reference the policy in test cases, add two files `tests/chart/templates/{constraint,constrainttemplate}-$NAME.yaml` with the same content as the existing files.
- Add test cases (in [gator-verify] syntax) to `tests/suite.yaml`. Execute the tests with `make check` as you go.

[gator-verify]: https://open-policy-agent.github.io/gatekeeper/website/docs/gator/#the-gator-verify-subcommand

# To consume a policy in a dependenct chart

Add this chart as a dependency: (For technical reasons, it is not allowed to use an alias for this dependency.)

```yaml
# in Chart.yaml
dependencies:
  - name: gatekeeper-policies
    repository: oci://keppel.eu-de-1.cloud.sap/ccloud-helm
    version: '>= 0.0.0'
```

Then write the ConstraintTemplate object like this (replacing the policy name appropriately):

```gotpl
{{ tuple . "GkHighCPURequests" | include "gatekeeper-policies.render-constraint-template" }}
```

And write the constraint object like this (replacing any attributes in the spec appropriately):

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: GkHighCPURequests
metadata:
  name: high-cpu-requests
spec:
  enforcementAction: dryrun
  match: {{ include "gatekeeper-policies.match-pods-and-pod-owners" . | indent 4 }}
  parameters:
    maxCpu: 6
```
