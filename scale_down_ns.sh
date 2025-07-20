#!/usr/bin/env bash

set -euo pipefail

# Usage: ./scale-down.sh <namespace>
NAMESPACE="${1:-}"

if [[ -z "$NAMESPACE" ]]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

echo "Scaling down workloads in namespace: $NAMESPACE"

# Scale Deployments
kubectl get deployments -n "$NAMESPACE" -o name | while read -r dep; do
  echo "Scaling down $dep"
  kubectl scale "$dep" -n "$NAMESPACE" --replicas=0 &
done

wait

# Scale StatefulSets
kubectl get statefulsets -n "$NAMESPACE" -o name | while read -r sts; do
  echo "Scaling down $sts"
  kubectl scale "$sts" -n "$NAMESPACE" --replicas=0 &
done

# Wait for all background processes to complete
wait

# # Remove finalizers from the EventBus before deleting it
# kubectl patch eventbus codefresh-eventbus -n "$NAMESPACE" \
#   --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' || true

# # Ignore the result of deleting the EventBus and properly detach it
# kubectl delete eventbus -n "$NAMESPACE" codefresh-eventbus --wait=false|| true

# kubectl patch eventbus codefresh-eventbus -n "$NAMESPACE" \
#   --type=json -p='[{"op": "remove", "path": "/metadata/finalizers"}]' || true
