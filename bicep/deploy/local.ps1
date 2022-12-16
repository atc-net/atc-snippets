###########################################################################
#
# Use this script to test locally
#
###########################################################################

Write-Host "Initialize local deployment" -ForegroundColor Blue

az account set --subscription ""

$location = "westeurope"

az deployment sub create `
    --location $location `
    --template-file main.bicep `
    --parameters .\main.parameters-dev.json #--what-if