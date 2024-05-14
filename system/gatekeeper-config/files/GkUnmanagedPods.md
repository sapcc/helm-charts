This check finds pods that are not managed by a declarative construct.

#### Why is this a problem?

Unmanaged pods cannot be moved away with `kubectl drain`.
We need to be able to drain nodes for routine upgrades or emergency maintenance.

#### How to fix this?

Deploy your pods through a declarative construct (Deployment, StatefulSet, DaemonSet, Job, etc.).
If you are trying to create a pod with `kubectl run`, use `kubectl create deployment` instead.
