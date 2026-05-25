#!/bin/bash
# Local build convenience — exercises the same Dockerfile that GitHub Actions
# and the GitLab CI pipeline use, without depending on either runner.
#
# Usage:
#   ./ci.sh                       # docker, tag :latest
#   ./ci.sh podman                # podman, tag :latest
#   ./ci.sh docker my-cdk:dev     # docker, custom tag
#   ./ci.sh podman my-cdk:dev     # podman, custom tag
set -euo pipefail

RUNTIME="${1:-docker}"
TAG="${2:-cdk:latest}"

case "$RUNTIME" in
  docker|podman) ;;
  *) echo "Unknown runtime '$RUNTIME' — use docker or podman" >&2; exit 2 ;;
esac

echo "Building $TAG with $RUNTIME"
"$RUNTIME" build -t "$TAG" "$(dirname "$0")"
