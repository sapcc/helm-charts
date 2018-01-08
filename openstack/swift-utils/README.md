## swift-utils

This chart contains additional utilities and seeds for Swift.

We used to have this in the "swift" chart, but this introduced a circular dependency: When the "swift" chart is
installed, the openstack-operator picks up the seeds in there and tries to create the Swift accounts defined in
the seeds, but this fails because Swift is not available yet. After Swift has started up, one would need to restart the
openstack-operator, so that it picks up the seeds again and creates the Swift accounts.

Therefore, everything that needs a Swift account is now in this chart, which is only installed when Swift has become
operational.
