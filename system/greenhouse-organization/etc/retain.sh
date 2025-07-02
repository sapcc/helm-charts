#!/usr/bin/bash
# SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
# SPDX-License-Identifier: Apache-2.0


function log(){
	ts=$(date +"%Y-%m-%d %H:%M:%S")
	echo "${ts} - $1"
}

all_keppel_images=$(kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | grep keppel | sort | uniq)
for keppel_image in $all_keppel_images; do
  # keppel.region.cloud.sap/ccloud-dockerhub-mirror/bitnami/oauth2-proxy:7.2.0
  # <      registry       > <            image                         > <tag>

  registry=$(echo ${keppel_image} | cut -f1 -d/)
  tag=$(echo ${keppel_image} | cut -f2 -d:)
  image=${keppel_image#"${registry}"/}  # remove registry/
  image=${image%:"$tag"}                # remove :tag

  response=$(curl -o /dev/null -s -w "%{http_code}" "https://${registry}/v2/${image}/manifests/${tag}")
  log "HTTP ${response} - ${keppel_image}"
done
