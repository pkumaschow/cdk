#!/bin/bash
# Local build convenience — exercises the same Dockerfile that GitHub Actions
# and the GitLab CI pipeline use, without depending on either runner.
#
# Usage:
#   ./ci.sh                                          # docker, tag :latest, Dockerfile
#   ./ci.sh podman                                   # podman, tag :latest, Dockerfile
#   ./ci.sh docker my-cdk:dev                        # docker, custom tag, Dockerfile
#   ./ci.sh podman my-cdk:dev                        # podman, custom tag, Dockerfile
#   ./ci.sh podman cdk:latest-java Dockerfile.java   # build the Java image
set -euo pipefail

RUNTIME="${1:-docker}"
TAG="${2:-cdk:latest}"
DOCKERFILE="${3:-Dockerfile}"

case "$RUNTIME" in
  docker|podman) ;;
  *) echo "Unknown runtime '$RUNTIME' — use docker or podman" >&2; exit 2 ;;
esac

echo "Building $TAG with $RUNTIME from $DOCKERFILE"
"$RUNTIME" build -f "$(dirname "$0")/$DOCKERFILE" -t "$TAG" "$(dirname "$0")"
