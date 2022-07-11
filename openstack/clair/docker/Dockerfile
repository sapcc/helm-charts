ARG CLAIR_VERSION
FROM quay.io/projectquay/clair:$CLAIR_VERSION
LABEL source_repository="https://github.com/sapcc/helm-charts/tree/master/openstack/clair/docker"

# We mostly use the upstream Clair image, but this gives us the chance to
# install updates when vulnerability reports are published.
USER root:root
RUN microdnf upgrade
USER nobody:nobody
