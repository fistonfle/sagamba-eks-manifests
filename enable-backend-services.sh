#!/usr/bin/env bash
# Enable all SAGAMBA backend services on EKS (fixes 503 on /v3/api-docs/*).
# Run from sagamba-eks-manifests directory. Requires kubectl and namespace sagamba.
set -e
NAMESPACE="${NAMESPACE:-sagamba}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Applying backend manifests..."
kubectl apply -f auth-service.yaml
kubectl apply -f organization-service.yaml
kubectl apply -f beneficiary-iga-services.yaml
kubectl apply -f group-loan-services.yaml
kubectl apply -f poverty-assessment-report-audit-services.yaml

echo "Scaling deployments to 2 replicas (in case they were 0)..."
for dep in auth-service organization-service beneficiary-service iga-service group-service loan-service poverty-service assessment-service report-service audit-service; do
  kubectl scale deployment "$dep" --replicas=2 -n "$NAMESPACE" 2>/dev/null || true
done

echo "Done. Watch pods: kubectl get pods -n $NAMESPACE -w"
