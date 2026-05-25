FROM node:22-alpine

# Cache-bust the apk-upgrade layer so each CI build pulls the latest
# Alpine security patches (CI passes APK_REFRESH=${{ github.run_id }}).
ARG APK_REFRESH=daily

# Upgrade all OS packages to pick up latest security patches (fixes OpenSSL CVEs)
RUN apk upgrade --no-cache

# Install Python 3, pip, and git
RUN apk add --no-cache python3 py3-pip git

# Update npm to latest by extracting tarball directly — npm publishes with all bundled deps included,
# so no npm install step is needed. This avoids the npm@10→npm@11 self-upgrade circular failure on Alpine.
# Extract to temp dir first, then clean-swap to avoid stale npm@10 files breaking npm@11.
RUN NPM_VERSION=$(npm view npm version) && \
    mkdir -p /tmp/npm-latest && \
    wget -qO- "https://registry.npmjs.org/npm/-/npm-${NPM_VERSION}.tgz" | \
    tar xz -C /tmp/npm-latest --strip-components=1 && \
    rm -rf /usr/local/lib/node_modules/npm && \
    mv /tmp/npm-latest /usr/local/lib/node_modules/npm

# Install AWS CDK v2 CLI
RUN npm install -g aws-cdk@2.1124.1

# Fix CVE-2026-33671: patch all picomatch instances to latest (ReDoS via extglob patterns).
# aws-cdk bundles its own nested copies so npm@11 upgrade alone does not cover them.
RUN PICO_VERSION=$(npm view picomatch version) && \
    find /usr/local/lib/node_modules -type d -name picomatch 2>/dev/null | \
    while read dir; do \
      wget -qO- "https://registry.npmjs.org/picomatch/-/picomatch-${PICO_VERSION}.tgz" | \
      tar xz --strip-components=1 -C "$dir"; \
    done

# Install CDK v2 Python library and AWS CLI
# wheel and setuptools upgraded explicitly to fix CVE-2026-24049 (path traversal in wheel.cli.unpack)
# urllib3>=2.7.0 pinned to fix CVE-2026-44431, CVE-2026-44432 (pulled in as awscli dep)
RUN pip3 install --no-cache-dir --break-system-packages \
    aws-cdk-lib==2.257.0 \
    constructs \
    awscli \
    'urllib3>=2.7.0' && \
    pip3 install --no-cache-dir --break-system-packages --upgrade wheel setuptools

RUN rm -rf /var/cache/apk/*

WORKDIR /src
RUN chown node:node /src

# OCI image labels — placed late so version-only changes don't invalidate
# the heavy RUN layers above. CDK_VERSION is passed in from CI.
ARG CDK_VERSION="unknown"
LABEL org.opencontainers.image.title="cdk" \
      org.opencontainers.image.description="AWS CDK CLI on node:22-alpine with Python toolchain" \
      org.opencontainers.image.source="https://github.com/pkumaschow/cdk" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${CDK_VERSION}"

USER node

ENTRYPOINT ["/usr/local/bin/cdk"]

CMD ["--help"]
