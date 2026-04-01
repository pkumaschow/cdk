FROM node:22-alpine

# Upgrade all OS packages to pick up latest security patches (fixes OpenSSL CVEs)
RUN apk upgrade --no-cache

# Install Python 3, pip, and git
RUN apk add --no-cache python3 py3-pip git

# Update npm to latest by extracting tarball directly — npm publishes with all bundled deps included,
# so no npm install step is needed. This avoids the npm@10→npm@11 self-upgrade circular failure on Alpine.
RUN NPM_VERSION=$(npm view npm version) && \
    wget -qO- "https://registry.npmjs.org/npm/-/npm-${NPM_VERSION}.tgz" | \
    tar xz -C /usr/local/lib/node_modules/npm --strip-components=1

# Install AWS CDK v2 CLI
RUN npm install -g aws-cdk

# Install CDK v2 Python library and AWS CLI
RUN pip3 install --no-cache-dir --break-system-packages \
    aws-cdk-lib \
    constructs \
    awscli

RUN rm -rf /var/cache/apk/*

WORKDIR /src
RUN chown node:node /src

USER node

ENTRYPOINT ["/usr/local/bin/cdk"]

CMD ["--help"]
