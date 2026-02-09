This check finds Helm releases that do not set `.Values.global.region`.

#### Why is this a problem?

We had some incidents where configuration for one region was accidentally deployed in a different region. The
GkRegionValueMismatch check forbids such deployments, but for this check to be effective, we must be able to identify
which region a Helm release belongs to.

#### How to fix?

Amend your deployment process to include the values file `$REGION/values/globals.yaml` or
`scaleout/s-$REGION/values/globals.yaml` from the cc/secrets repo in your `helm upgrade` invocation. If you are using
the shared Helm tasks, this is done by adjusting the `VALUES` parameter to include `local:globals` (for metal) or
`s-local:globals` (for scaleout).
