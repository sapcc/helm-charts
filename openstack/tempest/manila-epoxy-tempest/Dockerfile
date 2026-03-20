ARG BASE_IMAGE=keppel.eu-de-1.cloud.sap/ccloud/manila-tempest-plugin-python3:latest
FROM ${BASE_IMAGE}

LABEL source_repository="https://github.com/sapcc/helm-charts/openstack/tempest/manila-epoxy-tempest"

ARG TEMPEST_REPO=https://github.com/sapcc/tempest
ARG TEMPEST_BRANCH=ccloud-python3

ARG PLUGIN_REPO=https://github.com/sapcc/manila-tempest-plugin
ARG PLUGIN_BRANCH=ccloud-python3-epoxy

# Pre-clone the tempest repo during build to avoid runtime network dependency
RUN sudo git clone --branch ${TEMPEST_BRANCH} --depth 1 ${TEMPEST_REPO} /opt/tempest-repo \
    && sudo chown -R rally:rally /opt/tempest-repo

# Clone and install the manila-tempest-plugin from the specified branch
RUN sudo git clone --branch ${PLUGIN_BRANCH} --depth 1 ${PLUGIN_REPO} /opt/manila-tempest-plugin \
    && sudo chown -R rally:rally /opt/manila-tempest-plugin \
    && pip install --no-deps -e /opt/manila-tempest-plugin
