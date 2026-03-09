ARG BASE_IMAGE=keppel.eu-de-1.cloud.sap/ccloud/manila-tempest-plugin-python3:latest
FROM ${BASE_IMAGE}

LABEL source_repository="https://github.com/sapcc/helm-charts/openstack/tempest/manila-epoxy-tempest"

ARG TEMPEST_REPO=https://github.com/sapcc/tempest
ARG TEMPEST_BRANCH=ccloud-python3

# Pre-clone the tempest repo during build to avoid runtime network dependency
RUN sudo git clone --branch ${TEMPEST_BRANCH} --depth 1 ${TEMPEST_REPO} /opt/tempest-repo \
    && sudo chown -R rally:rally /opt/tempest-repo
