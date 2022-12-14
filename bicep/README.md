The files in this folder are intended as a getting started template for developing and deploying bicep modules on Azure DevOps.

# Local development

For local development, the file [local.ps1](./deploy/local.ps1) can be used to run the deployment locally.

The --what-if command can be uncommented to show changes that would be deployed.

## Pre-Requisites

- Login to azure using az cli
- Fill out the development subscription id in [local.ps1](./deploy/local.ps1)

# Azure DevOps

The [azure-pipeline.yml](azure-pipeline.yml) file contains the steps necessary to build and deploy the bicep files. It references the two templates [build.yml](./deploy/templates/build.yml) and [deploy.env.yml](./deploy/templates/deploy.env.yml)

# Bicep Configuration

An example [bicepconfig.json](bicepconfig.json) is also included. In this file common linting rules for developing bicep scripts have been added. This can be extended and/or tweaked to your liking.