#!/usr/bin/env bash
# Build production Docker image locally (fully containerized, no local PHP/Node needed).
# Replicates the same steps as the GitHub Actions CI pipeline.
#
# Usage: bash util/build-prod.sh [image-tag]
#   e.g.: bash util/build-prod.sh ghcr.io/rm-fm/azuracast:latest

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

IMAGE_TAG="${1:-ghcr.io/rm-fm/azuracast:latest}"
BUILDER_IMAGE="azuracast-builder:local"
BUILDER_CONTAINER="azuracast-asset-builder"

echo "==> Step 1/4: Writing git info..."
bash util/write_git_info.sh
chmod 777 .gitinfo

echo "==> Step 2/4: Building development image (for asset preparation)..."
docker buildx build --platform linux/amd64 --target development -t "$BUILDER_IMAGE" --load .

echo "==> Step 3/4: Preparing assets (locales, frontend, OpenAPI docs)..."
# Clean stale artifacts
rm -rf web/static/vite_dist translations/*.UTF-8 web/static/openapi.yml

# Run prepare commands inside the dev image (no services needed, just code generation)
docker rm -f "$BUILDER_CONTAINER" 2>/dev/null || true
docker create \
  --name "$BUILDER_CONTAINER" \
  --entrypoint "" \
  -e APPLICATION_ENV=testing \
  -e NODE_ENV=production \
  "$BUILDER_IMAGE" \
  bash -c "cd /var/azuracast/www && \
    backend/bin/console locale:generate && \
    backend/bin/console locale:import && \
    npm run build && \
    backend/bin/console azuracast:api:docs"

docker start -a "$BUILDER_CONTAINER"

# Extract prepared assets back to the build context
docker cp "$BUILDER_CONTAINER:/var/azuracast/www/translations/." translations/
docker cp "$BUILDER_CONTAINER:/var/azuracast/www/web/static/vite_dist/." web/static/vite_dist/
docker cp "$BUILDER_CONTAINER:/var/azuracast/www/web/static/openapi.yml" web/static/openapi.yml

docker rm "$BUILDER_CONTAINER"

echo "==> Step 4/4: Building production image: $IMAGE_TAG ..."
docker buildx build --platform linux/amd64 --target final -t "$IMAGE_TAG" --load .

echo ""
echo "==> Done! Production image built: $IMAGE_TAG"
echo "    Verify with: docker images $IMAGE_TAG"
