#!/bin/bash

set -euo pipefail

echo "Generating image digests..."
cp internal/overlays/overlays.yaml internal/overlays/overlays-generated.yaml

for NAME in $(yq '.overlays[].name' internal/overlays/overlays.yaml); do
    echo "Updating digest for ${NAME}"

    IMAGE=$(yq ".overlays[] | select(.name==\"${NAME}\").image" internal/overlays/overlays.yaml)
    yq -i ".overlays[] |= select(.name==\"${NAME}\") |= .digest=\"$(crane digest "${IMAGE}")\"" internal/overlays/overlays-generated.yaml
done
