This check finds references to several deprecated API versions in Helm manifests.

#### Why is this a problem?

We need to regularly upgrade Kubernetes to stay within the supported version range, but we can not upgrade when
references to old API versions are still around.

#### How to fix?

In your Helm chart templates, replace the deprecated API versions with their newer counterparts (refer to the
[Kubernetes API deprecation guide][deprecation-guide] for details). After this change, `helm upgrade` will understand
that we're still talking about the same object and not touch it, but `helm diff upgrade` may not be able to detect the
rename if the object contents also change at the same time. It is therefore recommended (though not strictly necessary)
to perform the API version change when you do not have any other diffs in your pipeline.

[deprecation-guide]: https://kubernetes.io/docs/reference/using-api/deprecation-guide/
