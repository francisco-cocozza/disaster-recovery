#!/usr/bin/env bash

set -euo pipefail

# Set the namespace where the Runtime is installed
NAMESPACE="runtime-alpha"

# Create a directory for backup files with a timestamp suffix
TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
BACKUP_DIR="backup-dir-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"


# Output files
CODEFRESH_TOKEN="$BACKUP_DIR/codefresh-token.yaml" ## Critical: the codefresh-token secret
CODEFRESH_GIT_INTEGRATION="$BACKUP_DIR/git-integration.yaml" ## the git-default secrets
CODEFRESH_USER_TOKEN="$BACKUP_DIR/codefresh-user-token.yaml" ## It will be referenced in the Helm chart values when reinstalling the Runtime
CODEFRESH_GIT_CREDENTIALS="$BACKUP_DIR/git-credentials.yaml" ## It will be referenced in the Helm chart values when reinstalling the Runtime
CLUSTERS_RAW="$BACKUP_DIR/clusters-raw.yaml"
CLUSTERS_CLEAN="$BACKUP_DIR/clusters-clean.yaml"
REPOS_RAW="$BACKUP_DIR/repos-raw.yaml"
REPOS_CLEAN="$BACKUP_DIR/repos-clean.yaml"
REPO_CREDS_RAW="$BACKUP_DIR/repo-creds-raw.yaml"
REPO_CREDS_CLEAN="$BACKUP_DIR/repos-creds-clean.yaml"

echo "ℹ️ Current context: $(kubectl config current-context)"
echo "ℹ️ Namespace: $NAMESPACE"


echo "🔄 Exporting codefresh-token secret..."
kubectl get secret codefresh-token -n "$NAMESPACE" -o yaml > "$CODEFRESH_TOKEN"

echo "🔄 Exporting git-integration secrets..."
kubectl get secrets -n "$NAMESPACE" -l "io.codefresh.integration-type=git" -o yaml > "$CODEFRESH_GIT_INTEGRATION"

echo "🔄 Exporting codefresh-user-token secret..."
kubectl get secret codefresh-user-token -n "$NAMESPACE" -o yaml > "$CODEFRESH_USER_TOKEN"

echo "🔄 Exporting git-credentials secret..."
kubectl get secret git-credentials -n "$NAMESPACE" -o yaml > "$CODEFRESH_GIT_CREDENTIALS"

echo "🔄 Exporting cluster secrets..."
kubectl get secrets -n "$NAMESPACE" -l "argocd.argoproj.io/secret-type=cluster" -o yaml > "$CLUSTERS_RAW"

echo "🧼 Cleaning cluster secrets..."
yq eval '
  del(
    .items[].metadata.uid,
    .items[].metadata.resourceVersion,
    .items[].metadata.creationTimestamp,
    .items[].metadata.managedFields,
    .items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
    .items[].metadata.ownerReferences,
    .items[].metadata.namespace
  )
' "$CLUSTERS_RAW" > "$CLUSTERS_CLEAN"


echo "🔄 Exporting repository secrets..."
kubectl get secrets -n "$NAMESPACE" -l "argocd.argoproj.io/secret-type=repository" -o yaml > "$REPOS_RAW"

echo "🧼 Cleaning repository secrets..."
yq eval '
  del(
    .items[].metadata.uid,
    .items[].metadata.resourceVersion,
    .items[].metadata.creationTimestamp,
    .items[].metadata.managedFields,
    .items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
    .items[].metadata.namespace
  )
' "$REPOS_RAW" > "$REPOS_CLEAN"

echo "🔄 Exporting repo-creds secrets..."
kubectl get secrets -n "$NAMESPACE" -l "argocd.argoproj.io/secret-type=repo-creds" -o yaml > "$REPO_CREDS_RAW"

echo "🧼 Cleaning repo-creds secrets..."
yq eval '
  del(
    .items[].metadata.uid,
    .items[].metadata.resourceVersion,
    .items[].metadata.creationTimestamp,
    .items[].metadata.managedFields,
    .items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
    .items[].metadata.namespace
  )
' "$REPO_CREDS_RAW" > "$REPO_CREDS_CLEAN"

echo "✅ Done!"
echo "➡️ To apply to another cluster before restoring a Runtime:"
echo "kubectl config use-context <context-name>"
echo "kubectl apply -f $CODEFRESH_TOKEN -n $NAMESPACE"
echo "kubectl apply -f $CODEFRESH_GIT_INTEGRATION -n $NAMESPACE"
echo "kubectl apply -f $CODEFRESH_USER_TOKEN -n $NAMESPACE"
echo "kubectl apply -f $CODEFRESH_GIT_CREDENTIALS -n $NAMESPACE"
echo "kubectl apply -f $CLUSTERS_CLEAN -n $NAMESPACE"
echo "kubectl apply -f $REPOS_CLEAN -n $NAMESPACE"
echo "kubectl apply -f $REPO_CREDS_CLEAN -n $NAMESPACE"
