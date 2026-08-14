This check validates the name prefix for Ingress annotations.

#### Why is this a problem?

The default prefix that you will see in documentation pages and examples is `nginx.ingress.kubernetes.io/`, but we use
`ingress.kubernetes.io/` instead for backwards compatibility. Annotations with the default prefix are ineffective.

#### How to fix?

Use the prefix `ingress.kubernetes.io/` without the leading `nginx.` instead.
