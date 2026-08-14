This check validates required labels on Pods.

#### Why is this a problem?

Each Pod should have a `ccloud/support-group` label containing the name of the support group that is responsible for it.
Optionally, the `ccloud/service` label can be added to further route alerts within the support group. These labels will
be used for routing generic pod alerts.

Please refer to [the operations documentation][tags-definition] for more details on the labels that drive our support
process.

#### How to fix?

Add the missing labels, as reported. Usually you do not have to maintain labels on individual pod specs. They will be
added automatically if you have [owner-info][owner-info] defined on the level of the Helm chart.

#### I have added owner-info, but my deployments are still reported here. What's going on?

For pods that are managed by a deployment/daemonset/statefulset/job, this check expects labels on the PodSpec. (We do
not check every individual pod because the large number of violations would overwhelm the audit process.) However, for
existing deployments etc., we avoid unintentional pod restarts by not changing the PodSpec unless the deployment is
actively changed. To force an update of the labels in the PodSpec, remove the `ccloud/support-group` label on the object
containing the PodSpec. Note that this will do a rolling restart of all pods. For example:

```sh
kubectl label deployment/nginx ccloud/support-group-
```

[tags-definition]: https://operations.global.cloud.sap/docs/support/operation_model/tags/
[owner-info]: https://github.com/sapcc/helm-charts/tree/master/common/owner-inf
