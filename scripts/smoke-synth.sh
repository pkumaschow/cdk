#!/bin/sh
# Smoke test run INSIDE a built image: checks the pinned versions, then runs a real `cdk synth` of
# the matching app under smoke/ and asserts the template contains the expected resources. This
# exercises the CLI, the construct library and the language toolchain together, which a bare
# `cdk --version` cannot.
#
# Usage: scripts/smoke-synth.sh python|java
set -eu

VARIANT="${1:?usage: $0 python|java}"
ROOT=$(cd "$(dirname "$0")/.." && pwd)

case "$VARIANT" in
  python) DOCKERFILE="$ROOT/Dockerfile" ;;
  java)   DOCKERFILE="$ROOT/Dockerfile.java" ;;
  *) echo "unknown variant: $VARIANT" >&2; exit 2 ;;
esac

EXPECTED_CLI=$(grep -oE 'aws-cdk@[0-9.]+' "$DOCKERFILE" | head -1 | cut -d@ -f2)
ACTUAL_CLI=$(cdk --version | awk '{print $1}')
echo "cdk CLI: expected ${EXPECTED_CLI}, got ${ACTUAL_CLI}"
test "$EXPECTED_CLI" = "$ACTUAL_CLI"

# The Java image installs no library; its app pulls the same aws-cdk-lib version the Python image pins.
LIB_VERSION=$(grep -oE 'aws-cdk-lib==[0-9.]+' "$ROOT/Dockerfile" | head -1 | cut -d= -f3)
test -n "$LIB_VERSION"

if [ "$VARIANT" = python ]; then
  ACTUAL_LIB=$(python3 -c 'from importlib.metadata import version; print(version("aws-cdk-lib"))')
  echo "aws-cdk-lib: expected ${LIB_VERSION}, got ${ACTUAL_LIB}"
  test "$LIB_VERSION" = "$ACTUAL_LIB"
fi

# Synth in a scratch copy: the image runs as `node`, which may not own the checkout.
WORK=$(mktemp -d)
cp -R "$ROOT/smoke/$VARIANT/." "$WORK/"
cd "$WORK"

export CDK_DISABLE_CLI_TELEMETRY=true
if [ "$VARIANT" = java ]; then
  cdk synth --no-notices --quiet --output cdk.out --app "mvn -e -q -Dcdk.lib.version=${LIB_VERSION} compile exec:java"
else
  cdk synth --no-notices --quiet --output cdk.out
fi

TEMPLATE=cdk.out/SmokeStack.template.json
test -s "$TEMPLATE"
for RESOURCE in AWS::S3::Bucket AWS::SQS::Queue; do
  grep -q "\"$RESOURCE\"" "$TEMPLATE" || { echo "missing $RESOURCE in $TEMPLATE" >&2; exit 1; }
done

echo "smoke test passed: cdk ${ACTUAL_CLI} synthesized SmokeStack (${VARIANT}, aws-cdk-lib ${LIB_VERSION})"
