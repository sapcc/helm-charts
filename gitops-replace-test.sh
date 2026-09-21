#!/usr/bin/env bash
# Empirical test: does kubectl replace -f succeed where kubectl apply fails,
# and what happens to the controller-set URL + caBundle fields?
#
# Companion to gitops-reapply-test.sh (which proved kubectl apply fails with
# validation error). This script tests kubectl replace -f as an alternative.
#
# Test plan:
#   1. Apply VWC with clientConfig.service (initial deploy)
#   2. Manually patch live state to URL form + caBundle (simulates webhook-injector)
#   3. kubectl replace -f with original Service-form manifest
#   4. Observe: did replace succeed? did it clobber URL/caBundle?
#   5. Run a second back-to-back replace to confirm pattern
#
# Hypothesis under test:
#   replace SUCCEEDS (no validation rejection — only Service set in PUT body),
#   but CLOBBERS the URL and caBundle fields the controller wrote
#
# Required env:
#   KUBECONFIG points at the target cluster (e.g., m-qa-de-200 via u8s)

set -euo pipefail

NAME="gitops-replace-test-$(date +%Y%m%d-%H%M%S)-$$"
MANIFEST="/tmp/${NAME}.yaml"

cleanup() {
  echo
  echo "=== Cleanup ==="
  kubectl delete validatingwebhookconfiguration "$NAME" --ignore-not-found 2>&1 || true
  rm -f "$MANIFEST"
}
trap cleanup EXIT

# Source manifest (Service form, no caBundle, no URL) — what user/Concourse applies
cat > "$MANIFEST" <<EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: $NAME
webhooks:
  - name: gitops-replace-test.example.com
    admissionReviewVersions:
      - v1
    failurePolicy: Ignore
    sideEffects: None
    timeoutSeconds: 5
    clientConfig:
      service:
        name: nonexistent-service
        namespace: default
        path: /validate-test
    rules:
      - operations: [CREATE]
        apiGroups: ["nonexistent.gitops-test.example.com"]
        apiVersions: [v1]
        resources: [nonexistents]
EOF

echo
echo "###############################################################################"
echo "# Test: kubectl replace -f as alternative to kubectl apply"
echo "###############################################################################"

echo
echo "=== Step 1: Initial apply (Service form) ==="
kubectl apply -f "$MANIFEST"

echo
echo "=== Step 2: Live state after initial apply ==="
kubectl get validatingwebhookconfiguration "$NAME" -o json | jq '.webhooks[0].clientConfig'

echo
echo "=== Step 3: Manually rewrite to URL form + caBundle (simulates webhook-injector reconciler) ==="
kubectl patch validatingwebhookconfiguration "$NAME" --type=json -p='[
  {"op":"remove","path":"/webhooks/0/clientConfig/service"},
  {"op":"add","path":"/webhooks/0/clientConfig/url","value":"https://nonexistent-host.example.com:443/validate-test"},
  {"op":"add","path":"/webhooks/0/clientConfig/caBundle","value":"dGVzdC1jYS1idW5kbGUtcGxhY2Vob2xkZXI="}
]'

echo
echo "=== Step 4: Live state after manual rewrite (URL form + caBundle) ==="
kubectl get validatingwebhookconfiguration "$NAME" -o json | jq '.webhooks[0].clientConfig'

echo
echo "=== Step 5: CRITICAL — kubectl replace -f with original Service-form manifest ==="
echo "(does it succeed where apply failed? does it clobber URL/caBundle?)"
START=$(date +%s%N)
if kubectl replace -f "$MANIFEST" 2>&1; then
  RC=0
  echo "RESULT: replace SUCCEEDED"
else
  RC=$?
  echo "RESULT: replace FAILED with rc=$RC"
fi
END=$(date +%s%N)
DURATION_MS=$(( (END - START) / 1000000 ))
echo "replace call duration: ${DURATION_MS}ms"

echo
echo "=== Step 6: Live state IMMEDIATELY after replace ==="
echo "(this is the 'window' state — what would a webhook callback see?)"
kubectl get validatingwebhookconfiguration "$NAME" -o json | jq '.webhooks[0].clientConfig'

echo
echo "=== Step 7: managedFields after replace ==="
kubectl get validatingwebhookconfiguration "$NAME" --show-managed-fields -o json 2>/dev/null \
  | jq '.metadata.managedFields' \
  || echo "(managedFields not visible — use kubectl --show-managed-fields)"

echo
echo "=== Step 8: Second back-to-back replace (confirms pattern) ==="
echo "(re-patch first to simulate reconciler racing back in)"
kubectl patch validatingwebhookconfiguration "$NAME" --type=json -p='[
  {"op":"remove","path":"/webhooks/0/clientConfig/service"},
  {"op":"add","path":"/webhooks/0/clientConfig/url","value":"https://nonexistent-host.example.com:443/validate-test"},
  {"op":"add","path":"/webhooks/0/clientConfig/caBundle","value":"dGVzdC1jYS1idW5kbGUtcGxhY2Vob2xkZXI="}
]'
echo "Live state before second replace:"
kubectl get validatingwebhookconfiguration "$NAME" -o json | jq '.webhooks[0].clientConfig'

START=$(date +%s%N)
kubectl replace -f "$MANIFEST"
END=$(date +%s%N)
DURATION_MS=$(( (END - START) / 1000000 ))
echo "second replace duration: ${DURATION_MS}ms"

echo "Live state after second replace:"
kubectl get validatingwebhookconfiguration "$NAME" -o json | jq '.webhooks[0].clientConfig'

echo
echo "###############################################################################"
echo "# Summary:"
echo "#"
echo "# - Step 5 result: did replace succeed? (compare with apply, which failed)"
echo "# - Step 6 final state: was URL clobbered? was caBundle clobbered?"
echo "# - Step 8: same pattern observed back-to-back?"
echo "#"
echo "# Implication: if replace clobbers URL+caBundle, every replace creates a"
echo "# 'window' (until reconciler races in) where the webhook callback fails:"
echo "#   - DNS: clientConfig.service points at non-existent workerless Service"
echo "#   - TLS: empty caBundle, can't verify cert"
echo "# With failurePolicy: Fail, this window blocks user CRD writes."
echo "###############################################################################"
