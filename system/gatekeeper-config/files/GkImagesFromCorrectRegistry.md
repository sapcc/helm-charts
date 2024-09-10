This check finds containers that do not pull their images from Keppel in the correct region.

#### Why is this a problem?

By pulling your images from the same region as your Pod deployment, you benefit from higher download bandwidth and lower
latencies compared to pulling from a different region. This is especially true for big images.

#### How to fix?

Replace your current registry with the appropriate regional registry value as defined in `$REGION/values/globals.yaml`
file from cc/secrets repo.

Instead of manually specifying the regional registry value, it is recommended to amend your deployment process to
include the `globals.yaml` file in your `helm upgrade` invocation, then you can reference the specific value directly in
your Helm chart ([example][example]).

[example]: (https://github.com/sapcc/helm-charts/blob/f1e70530f2f7e7784ac9c15886dfe57914b5ca2d/system/doop-central/templates/deployment.yaml#L36)
