<#
  .SYNOPSIS
  Deploys Azure Databricks instance

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Databricks instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER location
  Specifies the location where the services are deployed. Default is West Europe

  .PARAMETER resourceGroupName
  Specifies the name of the resource group

  .PARAMETER databricksName
  Specifies the name of the Databricks workspace

  .PARAMETER tenantId
  Specifies the tenant id

  .PARAMETER clientId
  Specifies the client id for the Service Principle

  .PARAMETER clientSecret
  Specifies the client secret for the Service Principle

  .PARAMETER objectId
  Specifies the object id for the Service Principle

  .PARAMETER logAnalyticsId
  Specifies the id for the log analytics workspace

  .PARAMETER logAnalyticsKey
  Specifies the primary for the log analytics workspace

  .PARAMETER resourceTags
  Specifies the tag elements that will be used to tag the deployed services

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]
  $location = "westeurope",

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $tenantId,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $resourceGroupName,

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $databricksName,

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $clientId,

  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $objectId,

  [Parameter(Mandatory=$true)]
  [securestring]
  $clientSecret,

  [Parameter(Mandatory=$true)]
  [string]
  $logAnalyticsId,

  [Parameter(Mandatory=$true)]
  [string]
  $logAnalyticsKey,

  [Parameter(Mandatory = $false)]
  [string[]] $resourceTags = @()
)

#############################################################################################
# Configure names and options
#############################################################################################

# import utility functions
. "$PSScriptRoot\utilities\set_DatabricksSpnAdminUser.ps1"
. "$PSScriptRoot\utilities\convertTo_DatabricksPersonalAccessToken.ps1"
. "$PSScriptRoot\utilities\enable_SparkMonitoringToLogAnalytics.ps1"
. "$PSScriptRoot\utilities\set_DatabricksGlobalInitScript.ps1"

$subscriptionId = az account show --query id

Throw-WhenError -output $subscriptionId

###############################################################################################
# Provision Databricks Workspace resources
###############################################################################################
Write-Host "Provision Databricks Workspace" -ForegroundColor DarkGreen

Write-Host "  Checking if already exists" -ForegroundColor DarkYellow
$dbWorkspace = (az databricks workspace list --query "[?name == '$($databricksName)']") | ConvertFrom-Json

If ($dbWorkspace.Count -eq 0) {
  Write-Host "  Deploying Databricks template" -ForegroundColor DarkYellow
  $output = az deployment group create `
    --resource-group $resourceGroupName `
    --template-file "databricks/arm-templates/databricks-workspace.json" `
    --parameters workspaceName=$databricksName

  Throw-WhenError -output $output
}

Write-Host "  Tagging Databricks Workspace" -ForegroundColor DarkYellow
$output = az resource tag `
  --resource-group $resourceGroupName `
  --name $databricksName `
  --resource-type "Microsoft.Databricks/workspaces" `
  --tags $resourceTags

Throw-WhenError -output $output

$resourceId = az resource show `
  --resource-group $resourceGroupName `
  --name $databricksName `
  --resource-type "Microsoft.Databricks/workspaces" `
  --query id
$resourceId = $resourceId.Replace('"','')

Throw-WhenError -output $resourceId

$workspaceUrl = az resource show `
  --resource-group $resourceGroupName `
  --name $databricksName `
  --resource-type "Microsoft.Databricks/workspaces" `
  --query properties.workspaceUrl
$workspaceUrl = $workspaceUrl.Replace('"','')

Throw-WhenError -output $workspaceUrl

###############################################################################################
# Initialize Databricks
###############################################################################################
Write-Host "Initialize Databricks Configuration" -ForegroundColor Green

Write-Host "  Install Databricks CLI" -ForegroundColor DarkYellow
pip install --upgrade pip --quiet
pip install --upgrade databricks-cli --quiet

Write-Host "  Assign SPN with RBAC owner role to the Databricks Workspace to allow SPN access to the Databricks API" -ForegroundColor DarkYellow
$output = az role assignment create --assignee $objectId --role "Owner" --scope  $resourceId
Throw-WhenError -output $output

Write-Host "  Add the SPN to the Databricks Workspace as an admin user" -ForegroundColor DarkYellow
$accessToken = Set-DatabricksSpnAdminUser `
  -tenantId $tenantId `
  -clientId $clientId `
  -clientSecret $clientSecret `
  -workspaceUrl $workspaceUrl `
  -resourceId $resourceId

Write-Host "  Generate SPN personal access token" -ForegroundColor DarkYellow
$token = ConvertTo-DatabricksPersonalAccessToken `
  -workspaceUrl $workspaceUrl `
  -bearerToken $accessToken

Write-Host "  Generate .databrickscfg" -ForegroundColor DarkYellow
Set-Content ~/.databrickscfg "[DEFAULT]"
Add-Content ~/.databrickscfg "host = https://$workspaceUrl"
Add-Content ~/.databrickscfg "token = $token"
Add-Content ~/.databrickscfg ""

###############################################################################################
# Set up Spark Monitoring Library
###############################################################################################
Write-Host "  Setting up Spark Monitoring Library" -ForegroundColor DarkYellow

Enable-SparkMonitoringToLogAnalytics `
  -logAnalyticsWorkspaceId $logAnalyticsId `
  -logAnalyticsWorkspaceKey $logAnalyticsKey `
  -subscriptionId $subscriptionId `
  -resourceGroup $resourceGroupName `
  -resourceName $databricksName

###############################################################################################
# Set up pyodbc driver
###############################################################################################
Write-Host "  Setting up pyodbc driver" -ForegroundColor DarkYellow

dbfs mkdirs dbfs:/databricks/drivers
dbfs cp --overwrite (Resolve-Path -Relative "$PSScriptRoot\utilities\drivers\msodbcsql17_17.7.2.1-1_amd64.deb") dbfs:/databricks/drivers/msodbcsql17_amd64.deb

Set-DatabricksGlobalInitScript `
  -workspaceUrl $workspaceUrl `
  -bearerToken $accessToken `
  -initScriptName "pyodbc-driver" `
  -initScriptContent (Get-Content "$PSScriptRoot\utilities\drivers\pyodbc-driver.sh" -Raw)