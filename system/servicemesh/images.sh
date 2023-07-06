#cr.l5d.io/linkerd/proxy:stable-2.13.5
#cr.l5d.io/linkerd/controller:stable-2.13.5
#cr.l5d.io/linkerd/policy-controller:stable-2.13.5
#cr.l5d.io/linkerd/proxy-init:v2.2.1
#cr.l5d.io/linkerd/debug:stable-2.13.5

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy:stable-2.13.5 --build-arg IMAGE="cr.l5d.io/linkerd/proxy:stable-2.13.5" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy:stable-2.13.5

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/controller:stable-2.13.5 --build-arg IMAGE="cr.l5d.io/linkerd/controller:stable-2.13.5" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/controller:stable-2.13.5

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/policy-controller:stable-2.13.5 --build-arg IMAGE="cr.l5d.io/linkerd/policy-controller:stable-2.13.5" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/policy-controller:stable-2.13.5

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy-init:v2.2.1 --build-arg IMAGE="cr.l5d.io/linkerd/proxy-init:v2.2.1" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy-init:v2.2.1

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/debug:stable-2.13.5 --build-arg IMAGE="cr.l5d.io/linkerd/debug:stable-2.13.5" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/debug:stable-2.13.5
