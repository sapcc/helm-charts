This check rejects `-snippet` annotations on Ingress objects.

#### Why is this a problem?

Usage of `-snippet` annotations is not allowed to prevent unauthorized access to Kubernetes objects as described in
CVE-2021-25742.

#### How to fix?

If you specify a `-snippet` annotation on your Ingress, it is essentially a no-op (i.e. ineffective). If needed, they
must go to the Ingress controller configuration. Get in touch with Arno Uhlig for a solution.
