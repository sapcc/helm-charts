This check finds Ingress annotations using the `ingress.kubernetes.io/` prefix
that have not been migrated to the newer `nginx.ingress.kubernetes.io/` prefix.

#### Why is this a problem?

When we first set up ingress-nginx, we did so using the old prefix (without `nginx.`).
In the meantime, ingress-nginx switched their default to the newer prefix (with `nginx.`).
This nonstandard configuration is causing confusion, so we want to clean it up.

#### How to fix?

In your Ingress object declaration, copy the reported annotation to the new key while leaving the value unchanged.
**Leave the old key untouched.**
For this phase of the migration, ingress-nginx is still inspecting the old key.
Once everyone has duplicated their annotations under the new prefix, we will flip the configuration of ingress-nginx to the new prefix.
