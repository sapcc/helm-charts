LINKERD_VERSION=stable-2.14.6
LINKERD_PROXY_INIT_VERSION=v2.2.3
LINKERD_EXTENSION_INIT_VERSION=v0.1.0
PROMETHEUS_VERSION=v2.48.0

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/proxy:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/controller:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/controller:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/controller:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/policy-controller:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/policy-controller:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/policy-controller:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy-init:$LINKERD_PROXY_INIT_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/proxy-init:$LINKERD_PROXY_INIT_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/proxy-init:$LINKERD_PROXY_INIT_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/debug:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/debug:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/debug:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/metrics-api:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/metrics-api:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/metrics-api:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/tap:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/tap:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/tap:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/web:$LINKERD_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/web:$LINKERD_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/web:$LINKERD_VERSION

docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/linkerd/extension-init:$LINKERD_EXTENSIN_INIT_VERSION --build-arg IMAGE="cr.l5d.io/linkerd/extension-init:$LINKERD_EXTENSIN_INIT_VERSION" - < Dockerfile
docker push keppel.eu-de-1.cloud.sap/ccloud/linkerd/extension-init:$LINKERD_EXTENSION_INIT_VERSION

docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/prom/prometheus:$PROMETHEUS_VERSION
