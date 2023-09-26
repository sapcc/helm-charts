This check validates annotations on Ingress objects.

#### Why is this a problem?

Usage of `-snippet` annotations is not allowed to prevent unauthorized access to Kubernetes objects as described in
CVE-2021-25742.

Starting in v0.22.0, Ingress definitions using the annotation `rewrite-target` are not backwards compatible with
previous versions. In v0.22.0 and beyond, any substrings within the request URI that need to be passed to the rewritten
path must explicitly be defined in a capture group.

#### How to fix?

If you specify a `-snippet` annotation on your Ingress, it is essentially a no-op (i.e. ineffective). If needed, they
must go to the Ingress controller configuration. Get in touch with Arno Uhlig for a solution.

For `rewrite-target` annotation, you must switch to the new syntax ([example][example]).

[example]: https://github.com/kubernetes/ingress-nginx/blob/main/docs/examples/rewrite/README.md#rewrite-target
