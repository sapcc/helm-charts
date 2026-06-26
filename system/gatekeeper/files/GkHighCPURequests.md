This check finds Pods that request more than 6 CPU.

#### Why is this a problem?

aPod VM(s) all have 10 CPU in total. Pods that request more than 6 CPU will have difficulties getting scheduled due to
the number of DaemonSet pods (logging, monitoring, etc.) already running on all nodes.

#### How to fix?

Consider scaling by number of Pods instead of using e.g. a single Pod. You can also consider deploying to other clusters
(i.e scaleout) instead of the baremetal controlplane.
