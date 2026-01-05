#!/usr/bin/env bash

set -euo pipefail

# Directory where the Helm repository (index.yaml + .tgz files) will be created.
# You can override this with the first argument, e.g.:
#   ./build-helm-repo.sh docs
REPO_DIR="${1:-helm-repo}"

# Base URL where the Helm repo will be hosted.
# Override with the second argument, e.g.:
#   ./build-helm-repo.sh docs https://your-org.github.io/crossplane-demo
REPO_URL="${2:-https://kwong.github.io/crossplane-demo}"

echo "Using repo directory: ${REPO_DIR}"
echo "Using repo URL:       ${REPO_URL}"

mkdir -p "${REPO_DIR}"

CHARTS=(
  "charts/crossplane-gcp"
)

for CHART_DIR in "${CHARTS[@]}"; do
  if [ -f "${CHART_DIR}/Chart.yaml" ]; then
    echo "Packaging chart in ${CHART_DIR}..."
    helm package "${CHART_DIR}" -d "${REPO_DIR}"
  else
    echo "Skipping ${CHART_DIR} (no Chart.yaml found)"
  fi
done

echo "Generating Helm repo index in ${REPO_DIR}..."
helm repo index "${REPO_DIR}" --url "${REPO_URL}"

echo "Helm repository built in ${REPO_DIR}"


