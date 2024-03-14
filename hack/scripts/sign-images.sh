#!/bin/bash

set -euo pipefail

EXTERNAL_OVERLAY_IMAGES=$(crane export "${OVERLAYS_IMAGE_REF}" | tar x --to-stdout overlays.yaml | yq '.overlays[] | .image + "@" + .digest')
OVERLAY_IMAGE_DIGEST=$(crane digest "${OVERLAYS_IMAGE_REF}")

for IMAGE in ${EXTERNAL_OVERLAY_IMAGES} ${OVERLAYS_IMAGE_REF}@${OVERLAY_IMAGE_DIGEST}; do
    echo '==>' "${IMAGE}"

    cosign verify \
        "${IMAGE}" \
        --certificate-identity-regexp '@siderolabs\.com$' \
        --certificate-oidc-issuer https://accounts.google.com || \
        cosign sign --yes "${IMAGE}"

done
