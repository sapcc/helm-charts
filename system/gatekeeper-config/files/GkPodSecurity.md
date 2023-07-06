This check validates pods using privilege escalation features against a predefined allowlist.

#### Why is this important?

Privilege escalation features are necessary to implement several of our core functions. For example, Swift needs
privileged access to the storage nodes to format and mount its disks; Neutron needs privileged access to the network
interfaces to reach into customer networks; etc. In order to reduce the risks of these privileged operations
interfering with each other, this policy restricts their use to known and validated usecases.

#### How do I extend the allowlist to cover my new requirements?

Set up your desired deployment in qa-de-1 (where this check runs in audit-only mode) with the minimum required
privileges. Then ask in \#team\_services; we can set up the respective allowlist entry for you. Once the allowlist is
deployed to prod, you can go ahead with your deployment to prod.

#### Why not use the standard [PodSecurity Admission][psa] webhook for this?

We want to avoid adding more admission webhooks than necessary, since every webhook is in the hot path for all updates
of Kubernetes objects. Also, Gatekeeper policies are much more versatile and can match allowed configurations more
precisely.

[psa]: https://kubernetes.io/docs/concepts/security/pod-security-admission/
