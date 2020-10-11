# cdk docker image

This dockerfile builds an alpine image containing the requirements for running the aws-cdk command line tool.

Python 3.9 is included in the container.

Note: this needs more work before it can be useful.

Pull latest image from docker hub

```
docker pull pkumaschow/cdk
```

Create a bash alias n your .bashrc file to transparently call the image from your bash terminal.

```
alias cdk='project_name=${PWD##*/};docker run --rm -u "$(id -u):$(id -g)" -w /$project_name -v `pwd`/:/$project_name pkumaschow/cdk'
```

cdk uses the name of the current directory to name various elements of the project, including classes, subfolders and files.

Example for creating new project using the aliased command above:

```
mkdir my-project
cd my-project
cdk init app --language python
```
Exactly as documented here: https://docs.aws.amazon.com/cdk/latest/guide/work-with-cdk-python.html

