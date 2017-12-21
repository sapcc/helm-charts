## swift-common

This chart contains common utilities used for Swift and Swift Utils, like
startup logic or the unmount logic when swift-drive-autopilot wants to
unmount a faulty disk.

**IMPORTANT**
Changes in `bin` should also increase the version in the values.yaml to allow
a deployment spec update in the consuming charts.
