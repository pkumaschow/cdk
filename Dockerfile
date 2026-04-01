FROM node:22-alpine3.21

# Install Python 3, pip, and git
RUN apk add --no-cache python3 py3-pip git

# Install AWS CDK v2 CLI
RUN npm install -g aws-cdk

# Install CDK v2 Python library and AWS CLI
RUN pip3 install --no-cache-dir --break-system-packages \
    aws-cdk-lib \
    constructs \
    awscli

RUN rm -rf /var/cache/apk/*

WORKDIR /src

ENTRYPOINT ["/usr/local/bin/cdk"]

CMD ["--help"]
