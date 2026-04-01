FROM node:22-alpine

# Upgrade all OS packages to pick up latest security patches (fixes OpenSSL CVEs)
RUN apk upgrade --no-cache

# Install Python 3, pip, and git
RUN apk add --no-cache python3 py3-pip git

# Update npm to latest (fixes CVE-2026-23745/23950/24842/26960/29786/31802 in bundled node-tar)
RUN npm install -g npm@latest

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
