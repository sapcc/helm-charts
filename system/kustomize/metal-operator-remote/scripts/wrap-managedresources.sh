#!/bin/bash
# wrap-managedresources.sh
# Reads multi-document YAML from stdin and produces ManagedResource+Secret pairs.
# Naming convention matches system/metal-operator-remote/templates/managedresource.yaml:
#   mr-<KIND_INITIALS_LOWERCASE>-<resource-name-sanitized>
set -euo pipefail

INPUT=$(cat)
COUNT=$(echo "$INPUT" | yq -N 'tag' | wc -l | tr -d ' ')

first=true
for i in $(seq 0 $((COUNT - 1))); do
  doc=$(echo "$INPUT" | yq "select(documentIndex == $i)")

  kind=$(echo "$doc" | yq '.kind // ""')
  name=$(echo "$doc" | yq '.metadata.name // ""' | tr '.:' '-')

  # Skip empty or null documents
  [ -z "$kind" ] || [ "$kind" = "null" ] && continue
  [ -z "$name" ] || [ "$name" = "null" ] && continue

  # Generate prefix from uppercase letters of kind (e.g., CustomResourceDefinition → crd)
  prefix=$(echo "$kind" | grep -o '[A-Z]' | tr '[:upper:]' '[:lower:]' | tr -d '\n')
  mrname="mr-${prefix}-${name}"

  # Base64 encode the document
  encoded=$(echo "$doc" | base64 | tr -d '\n')

  # Output separator between pairs
  if [ "$first" = true ]; then
    first=false
  else
    echo "---"
  fi

  # Output ManagedResource + Secret pair
  cat <<EOF
apiVersion: resources.gardener.cloud/v1alpha1
kind: ManagedResource
metadata:
  name: ${mrname}
spec:
  secretRefs:
  - name: ${mrname}
---
apiVersion: v1
kind: Secret
metadata:
  name: ${mrname}
type: Opaque
data:
  objects.yaml: ${encoded}
EOF
done
