#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

buildkite-agent artifact download "masterops_*.deb" .

DEB_FILE=$(ls masterops_*.deb | head -n1)
echo "[upload] file to upload: ${DEB_FILE}"

if [[ -z "${BUILDKITE_PACKAGES_TOKEN:-}" ]]; then
  echo "[upload] ERROR: BUILDKITE_PACKAGES_TOKEN is empty"
  exit 1
fi

if [[ -z "${DEB_FILE}" ]]; then
  echo "[upload] ERROR: no .deb file found"
  exit 1
fi

curl -sS -w "\nHTTP_STATUS:%{http_code}\n" -X POST \
  -H "Authorization: Bearer ${BUILDKITE_PACKAGES_TOKEN}" \
  -F "file=@${DEB_FILE}" \
  "https://api.buildkite.com/v2/packages/organizations/mohamed-tarek/registries/masterops/packages"
