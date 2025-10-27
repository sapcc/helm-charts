## Trivy for Keppel

This is the [Trivy](https://github.com/aquasecurity/trivy) deployment that is bundled with Keppel.
Its API is not accessible from outside of Keppel, users can only consume its capabilities indirectly through Keppel.
Trivy is not part of the Keppel chart because it should run in scaleout to save resources in the control plane clusters.
