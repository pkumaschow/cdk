# cdk docker image

This dockerfile builds an alpine image containing the requirements for running the aws-cdk command line tool.

Create a bash alias n your .bashrc file to transparently call the image from your bash terminal.

```
alias cdk='project_name=${PWD##*/};docker run --rm -w /$project_name -v `pwd`/:/$project_name pkumaschow/cdk'
```

cdk uses the name of the current directory to name various elements of the project, including classes, subfolders and files.

Example for creating new project using the aliased command above:

```
mkdir my-project
cd my-project
cdk init app --language python
```
Exactly as documented here: https://docs.aws.amazon.com/cdk/latest/guide/work-with-cdk-python.html
