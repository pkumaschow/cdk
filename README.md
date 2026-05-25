# cdk docker image

This Dockerfile builds an Alpine-based image with the AWS CDK command line tool
and the Python toolchain pre-installed so it can build, synthesise, and deploy
both TypeScript/JavaScript and Python CDK applications without any local Node
or Python install on the host.

The image is built on `node:22-alpine` and includes Python 3 (via Alpine apk),
the AWS CDK CLI (`aws-cdk`), the Python construct library (`aws-cdk-lib`), and
the AWS CLI.

## Pulling

The image is published to two registries on every push to `main`.

**Docker Hub** (public):
```
docker pull pkumaschow/cdk:latest
docker pull pkumaschow/cdk:2.1124.1   # any CDK version tag
```

**Homelab GitLab registry** (private):
```
docker login gitlab.homelab.com:5050 -u <user>
docker pull gitlab.homelab.com:5050/peterk/cdk:latest
docker pull gitlab.homelab.com:5050/peterk/cdk:2.1124.1
```

Use Docker Hub for anything outside the homelab; use the GitLab registry to
avoid the public hop when working from inside the LAN.

## Convenience alias

Add this to `~/.bashrc` to transparently call the image as if `cdk` were a
local command. It mounts the current directory and your AWS credentials into
the container, and runs as your own UID/GID so files created by `cdk` stay
owned by you on the host.

```
project_name=${PWD##*/}
alias cdk='docker run --rm -u "$(id -u):$(id -g)" \
  -w "/${project_name}" \
  -v "$(pwd)/:/${project_name}" \
  -v "$HOME/.aws:/home/node/.aws" \
  pkumaschow/cdk'
```

`cdk` uses the name of the current directory to name various elements of the
project (classes, subfolders, files), so always `cd` into your project first.

## Example: Python project

```
mkdir my-project && cd my-project
cdk init app --language python
```

See the upstream guide for Python apps:
https://docs.aws.amazon.com/cdk/latest/guide/work-with-cdk-python.html

## Example: TypeScript project

```
mkdir my-ts-project && cd my-ts-project
cdk init app --language typescript
```

## Example: full sample-app run

```
mkdir sample-app && cd sample-app
cdk init sample-app --language python
cdk deploy --require-approval never sample-app
cdk destroy -f sample-app
```
