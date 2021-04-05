## Clair for Keppel

This is the Clair deployment that is bundled with Keppel. Its API is not
accessible from outside of Keppel, users can only consume its capabilities
indirectly through Keppel. Clair is not part of the Keppel chart because it
needs to run in scaleout; the control plane clusters might not have enough
resources to support its rather large database.
