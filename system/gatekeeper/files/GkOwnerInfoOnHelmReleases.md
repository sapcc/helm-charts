This check finds Helm releases that do not define owner info.

#### Why is this a problem?

Owner info such as maintainer's name tells other operators who is responsible for a specific release.

#### How to fix?

Add owner-info chart as a dependency to your Helm chart and add the necessary configuration parameters to your chart's
`Values.yaml` file ([instructions][instructions]). The owner-chart will then deploy a ConfigMap that has all the
necessary owner info in the format that this policy expects.

[instructions]: https://github.com/sapcc/helm-charts/tree/master/common/owner-info
