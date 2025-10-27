This check finds containers that do not pull their image from Keppel.

#### Why is this a problem?

The Software Engineering Policy requires that we only run images from Keppel. Images from outside must be pulled from an
external replica account inside of Keppel, to benefit from compliance-relevant features such as audit logging and
vulnerability scanning.

#### How to fix?

We have set up a Docker Hub mirror at `keppel.$REGION.cloud.sap/ccloud-dockerhub-mirror`. The regional mirror is defined
in globals.yaml and can be referenced as `$.Values.global.dockerHubMirror` in most Helm charts ([example][example]).

If a particular image has not been mirrored yet, you need to `docker pull` it once from eu-de-1 with your logged-in
Docker client. Afterwards, the image can be pulled from all regions without login. There are also several other mirror
accounts for other upstream registries. Checkout your regional `globals.yaml` for reference.

#### What about circular dependencies?

If your pod pulls an image from Keppel, but Keppel needs that pod up and running to work, get in touch with Stefan
Majewsky and we'll figure out how to proceed.

[example]: https://github.com/sapcc/helm-charts/blob/409aa9940ecb600dafc0f9a20c973566af9eaf1f/openstack/backup-replication/templates/statsd-deployment.yaml#L29
