#!/usr/bin/env bash
# Empirical test: does kubectl/Flux reapply re-introduce a clientConfig.service
# field that a controller previously rewrote to clientConfig.url?
#
# This validates (or refutes) the GitOps reapply hazard analyzed in
# openspec/changes/replace-managedresource-with-dual-kustomize/design.md
# "Helm-vs-kustomize equivalence gap analysis" → "Why TargetWebhookReconciler
# Watch, not ExternalName / pre-rendered URLs".
#
# Test plan:
#   1. Apply VWC with clientConfig.service (simulates user / Concourse / Flux apply)
#   2. Patch live state to clientConfig.url (simulates webhook-injector reconciler)
#   3. Reapply original Service-form manifest (simulates next pipeline run)
#   4. Observe: did Service get re-added? Did the apply fail validation?
#
# Test runs three apply variants:
#   A. kubectl apply (client-side apply, default)
#   B. kubectl apply --server-side (SSA without --force-conflicts)
#   C. kubectl apply --server-side --force-conflicts
#
# Safety:
#   - Uses a uniquely-named throwaway VWC (no production resource touched)
#   - failurePolicy: Ignore + nonexistent service/group/resource (won't fire on real traffic)
#   - Trap-cleanup on any exit path
#   - Tested only on m-qa-de-200 (or whatever workerless cluster the operator chooses)
#
# Required env:
#   KUBECONFIG must point at the target cluster's admin kubeconfig with
#   permission to create/patch/delete ValidatingWebhookConfiguration.

set -euo pipefail

NAME="gitops-reapply-test-$(date +%Y%m%d-%H%M%S)-$$"
MANIFEST="/tmp/${NAME}.yaml"

cleanup() {
  echo
  echo "=== Cleanup ==="
  kubectl delete validatingwebhookconfiguration "$NAME" --ignore-not-found 2>&1 || true
  rm -f "$MANIFEST"
}
trap cleanup EXIT

# Source manifest (Service form) — what user / Concourse / Flux applies
cat > "$MANIFEST" <<EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: $NAME
webhooks:
  - name: gitops-reapply-test.example.com
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

run_test() {
  local apply_mode="$1"
  local apply_args="$2"

  echo
  echo "###############################################################################"
  echo "# Test variant: $apply_mode"
  echo "# kubectl apply args: $apply_args"
  echo "###############################################################################"

  # Clean any leftover from prior variant
  kubectl delete validatingwebhookconfiguration "$NAME" --ignore-not-found 2>&1 >/dev/null || true

  echo
  echo "=== Step 1: Initial apply (Service form) ==="
  kubectl apply -f "$MANIFEST" $apply_args

  echo
  echo "=== Step 2: Live state after initial apply ==="
  kubectl get validatingwebhookconfiguration "$NAME" -o yaml | yq '.webhooks[0].clientConfig'

  echo
  echo "=== Step 3: Manually rewrite to URL form (simulates webhook-injector reconciler) ==="
  kubectl patch validatingwebhookconfiguration "$NAME" --type=json -p='[
    {"op":"remove","path":"/webhooks/0/clientConfig/service"},
    {"op":"add","path":"/webhooks/0/clientConfig/url","value":"https://nonexistent-host.example.com:443/validate-test"}
  ]'

  echo
  echo "=== Step 4: Live state after manual rewrite ==="
  kubectl get validatingwebhookconfiguration "$NAME" -o yaml | yq '.webhooks[0].clientConfig'

  echo
  echo "=== Step 5: REAPPLY original Service-form manifest ==="
  echo "=== This is the critical test — does it succeed or fail? ==="
  if kubectl apply -f "$MANIFEST" $apply_args 2>&1; then
    echo
    echo "RESULT: apply SUCCEEDED"
  else
    rc=$?
    echo
    echo "RESULT: apply FAILED with rc=$rc"
  fi

  echo
  echo "=== Step 6: Live state after reapply ==="
  kubectl get validatingwebhookconfiguration "$NAME" -o yaml 2>/dev/null | yq '.webhooks[0].clientConfig' || echo "(VWC no longer exists)"

  echo
  echo "=== Step 7: managedFields (shows ownership for SSA modes) ==="
  kubectl get validatingwebhookconfiguration "$NAME" -o yaml 2>/dev/null | yq '.metadata.managedFields' || echo "(VWC no longer exists)"
}

run_test "A: kubectl apply (client-side, default)" ""
run_test "B: kubectl apply --server-side (no --force-conflicts)" "--server-side"
run_test "C: kubectl apply --server-side --force-conflicts" "--server-side --force-conflicts"

echo
echo "###############################################################################"
echo "# All 3 test variants complete. Summary:"
echo "#"
echo "# For each variant, examine:"
echo "#   - Step 5 result: did apply succeed or fail?"
echo "#   - Step 6 final state: is service re-added? is url preserved?"
echo "#"
echo "# Expected outcomes per pre-test analysis:"
echo "#   Variant A (CSA):   apply FAILS validation 'exactly one of url or service'"
echo "#   Variant B (SSA):   apply may succeed but with conflict on service field"
echo "#   Variant C (force): apply succeeds, service re-added (overwrites controller's removal)"
echo "###############################################################################"
