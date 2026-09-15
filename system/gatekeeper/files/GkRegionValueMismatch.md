This check finds Helm releases where `.Values.global.region` is set to a different region than the current one.

#### Why is this a problem?

We had some incidents where configuration for one region was accidentally deployed in a different region. This check
forbids such misdirected deployments.

#### How to fix?

Prefer CI-driven over manual deployments to reduce the chance of human error. If you have to do a manual deployment,
check that you're logged into the correct cluster before deploying.
