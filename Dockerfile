FROM node:22-alpine

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
RUN npm install -g aws-cdk

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
RUN pip3 install --no-cache-dir --break-system-packages \
    aws-cdk-lib \
    constructs \
    awscli && \
    pip3 install --no-cache-dir --break-system-packages --upgrade wheel setuptools

RUN rm -rf /var/cache/apk/*

WORKDIR /src
RUN chown node:node /src

USER node

ENTRYPOINT ["/usr/local/bin/cdk"]

CMD ["--help"]
