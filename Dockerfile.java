FROM node:22-alpine

# Cache-bust the apk-upgrade layer so each CI build pulls the latest
# Alpine security patches (CI passes APK_REFRESH=${{ github.run_id }}).
ARG APK_REFRESH=daily

# Upgrade all OS packages to pick up latest security patches (fixes OpenSSL CVEs)
RUN apk upgrade --no-cache

# Install the Java toolchain and git.
#   openjdk21 — JDK for compiling/running Java CDK apps
#   maven     — Java build tool invoked by `cdk synth`/`cdk deploy`
#   git       — required by `cdk init`
RUN apk add --no-cache openjdk21 maven git

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
RUN npm install -g aws-cdk@2.1128.0

# Patch nested vulnerable deps that aws-cdk vendors inside its own node_modules — npm upgrades
# alone do not cover these bundled copies. Each is replaced in-place with the latest published
# version across every nested directory:
#   picomatch        CVE-2026-33671 (ReDoS via extglob patterns)
#   brace-expansion  CVE-2026-33750, CVE-2026-45149 (ReDoS)
#   ip-address       CVE-2026-42338
RUN for pkg in picomatch brace-expansion ip-address; do \
      PKG_VERSION=$(npm view "$pkg" version) && \
      find /usr/local/lib/node_modules -type d -name "$pkg" 2>/dev/null | \
      while read dir; do \
        wget -qO- "https://registry.npmjs.org/${pkg}/-/${pkg}-${PKG_VERSION}.tgz" | \
        tar xz --strip-components=1 -C "$dir"; \
      done; \
    done

# Patch undici (bundled inside npm) within its v6 line. A major bump (v7/v8) could break npm's
# HTTP, so stay on the latest 6.x — fixes CVE-2026-12151 (DoS) and CVE-2026-9679 (header injection).
# Overwrite in place (NO rm of the dir — removing a lower-layer dir and recreating it does not
# survive image flattening on overlayfs). Version via node (npm's --json array is ascending) to
# avoid shell-sort quirks; the result is asserted so the build can't silently no-op.
RUN UNDICI_VERSION=$(npm view 'undici@^6' version --json | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(Array.isArray(d)?d[d.length-1]:d)') && \
    echo "Patching bundled undici -> ${UNDICI_VERSION}" && \
    find /usr/local/lib/node_modules -type d -name undici 2>/dev/null | \
    while read dir; do \
      wget -qO- "https://registry.npmjs.org/undici/-/undici-${UNDICI_VERSION}.tgz" | \
      tar xz --overwrite --strip-components=1 -C "$dir"; \
    done && \
    test "$(node -p "require('/usr/local/lib/node_modules/npm/node_modules/undici/package.json').version")" = "${UNDICI_VERSION}"

RUN rm -rf /var/cache/apk/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

WORKDIR /src
RUN chown node:node /src

# OCI image labels — placed late so version-only changes don't invalidate
# the heavy RUN layers above. CDK_VERSION is passed in from CI.
ARG CDK_VERSION="unknown"
LABEL org.opencontainers.image.title="cdk-java" \
      org.opencontainers.image.description="AWS CDK CLI on node:22-alpine with Java (JDK 21 + Maven) toolchain" \
      org.opencontainers.image.source="https://github.com/pkumaschow/cdk" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${CDK_VERSION}"

USER node

ENTRYPOINT ["/usr/local/bin/cdk"]

CMD ["--help"]
