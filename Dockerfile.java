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
#
# Alpine's maven bundles guava in its lib/ dir; swap it for the latest -jre release
# (CVE-2026-102554, fixed 33.7.2). The jar is checked against Maven Central's sha1, and
# maven must still start on the new jar with no other guava left beside it.
RUN apk add --no-cache openjdk21 maven git && \
    MVN_LIB=/usr/share/java/maven-3/lib && \
    M2=https://repo1.maven.org/maven2/com/google/guava/guava && \
    GUAVA_VERSION=$(wget -qO- "$M2/maven-metadata.xml" | grep -o '<version>[^<]*-jre</version>' | sed 's/<[^>]*>//g' | sort -V | tail -1) && \
    echo "Patching maven's bundled guava -> ${GUAVA_VERSION}" && \
    wget -qO /tmp/guava.jar "$M2/${GUAVA_VERSION}/guava-${GUAVA_VERSION}.jar" && \
    echo "$(wget -qO- "$M2/${GUAVA_VERSION}/guava-${GUAVA_VERSION}.jar.sha1")  /tmp/guava.jar" | sha1sum -c - && \
    rm -f "$MVN_LIB"/guava-*.jar && \
    mv /tmp/guava.jar "$MVN_LIB/guava-${GUAVA_VERSION}.jar" && \
    test "$(ls "$MVN_LIB"/guava-*.jar)" = "$MVN_LIB/guava-${GUAVA_VERSION}.jar" && \
    mvn -v >/dev/null

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
RUN npm install -g aws-cdk@2.1146.1

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
        tar xzm --strip-components=1 -C "$dir"; \
      done; \
    done

# Patch undici (bundled inside npm) within its v6 line. A major bump (v7/v8) could break npm's
# HTTP, so stay on the latest 6.x — fixes CVE-2026-12151 (DoS) and CVE-2026-9679 (header injection).
# Overwrite in place (NO rm of the dir — removing a lower-layer dir and recreating it does not
# survive image flattening on overlayfs). `tar -m` stamps extracted files with the current time:
# npm tarballs fix every mtime to 1985, so a same-size file (6.29.0 -> 6.29.1 package.json) looks
# unchanged to podman's layer diff and the patch is silently dropped. Version via node (npm's --json array is ascending) to
# avoid shell-sort quirks; the result is asserted so the build can't silently no-op.
RUN UNDICI_VERSION=$(npm view 'undici@^6' version --json | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(Array.isArray(d)?d[d.length-1]:d)') && \
    echo "Patching bundled undici -> ${UNDICI_VERSION}" && \
    find /usr/local/lib/node_modules -type d -name undici 2>/dev/null | \
    while read dir; do \
      wget -qO- "https://registry.npmjs.org/undici/-/undici-${UNDICI_VERSION}.tgz" | \
      tar xzm --overwrite --strip-components=1 -C "$dir"; \
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
