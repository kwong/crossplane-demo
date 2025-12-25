#!/usr/bin/env bash
set -euo pipefail

SECRET_NAME="gcp-access-token"
NAMESPACE="crossplane-system"

command -v gcloud >/dev/null 2>&1 || { echo "gcloud not found in PATH"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found in PATH"; exit 1; }

echo "Fetching GCP access token..."
TOKEN="$(gcloud auth print-access-token)" || { echo "failed to obtain access token"; exit 1; }
if [[ -z "$TOKEN" ]]; then
    echo "received empty token"
    exit 1
fi

echo "Updating secret ${SECRET_NAME} in namespace ${NAMESPACE}..."
kubectl delete secret "${SECRET_NAME}" -n "${NAMESPACE}" --ignore-not-found
kubectl create secret generic "${SECRET_NAME}" -n "${NAMESPACE}" --from-literal=token="${TOKEN}"

echo "Secret refreshed successfully."