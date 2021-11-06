<#
  .SYNOPSIS
  Deploys Azure Databricks instance

  .DESCRIPTION
  The deploy.ps1 script deploys an Azure Databricks instance using Azure CLI to a resource group in the relevant environment.

  .PARAMETER environmentType
  Specifies the environment type. Staging (DevTest) or Production

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

  .INPUTS
  None. You cannot pipe objects to deploy.ps1.

  .OUTPUTS
  None. deploy.ps1 does not generate any output.
#>
param (
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('DevTest', 'Production')]
  [string]
  $environmentType = "DevTest",

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
  [System.Security.Cryptography.X509Certificates.X509Certificate2]
  $certificate
)

#############################################################################################
# Configure names and options
#############################################################################################

# import utility functions
. "$PSScriptRoot\utilities\databricks.utilities.ps1"
. "$PSScriptRoot\utilities\set_DatabricksSpnAdminUser.ps1"
. "$PSScriptRoot\utilities\convertTo_DatabricksPersonalAccessToken.ps1"
. "$PSScriptRoot\utilities\include_FilesInFolder.ps1"

###############################################################################################
# Initialize Databricks
###############################################################################################
Write-Host "Initialize Databricks Configuration" -ForegroundColor DarkGreen

Write-Host "  Installing Databricks CLI" -ForegroundColor DarkYellow
pip install --upgrade pip --quiet
pip install --upgrade databricks-cli --quiet

Write-Host "  Get resource id" -ForegroundColor DarkYellow
$resourceId = az resource show `
  --resource-group $resourceGroupName `
  --name $databricksName `
  --resource-type "Microsoft.Databricks/workspaces" `
  --query id
$resourceId = $resourceId.Replace('"','')

Throw-WhenError -output $resourceId

Write-Host "  Get workspace url" -ForegroundColor DarkYellow
$workspaceUrl = az resource show `
  --resource-group $resourceGroupName `
  --name $databricksName `
  --resource-type "Microsoft.Databricks/workspaces" `
  --query properties.workspaceUrl
$workspaceUrl = $workspaceUrl.Replace('"','')

Throw-WhenError -output $workspaceUrl

# Write-Host "  Assign SPN with RBAC owner role to the Databricks Workspace to allow SPN access to the Databricks API" -ForegroundColor DarkYellow
# $output = az role assignment create --assignee $objectId --role "Owner" --scope $resourceId
# Throw-WhenError -output $output

Write-Host "  Adding the SPN to the Databricks Workspace as an admin user" -ForegroundColor DarkYellow
$accessToken = Set-DatabricksSpnAdminUser `
  -tenantId $tenantId `
  -clientId $clientId `
  -certificate $certificate `
  -workspaceUrl $workspaceUrl `
  -resourceId $resourceId

Write-Host "  Generating SPN personal access token" -ForegroundColor DarkYellow
$token = ConvertTo-DatabricksPersonalAccessToken `
  -workspaceUrl $workspaceUrl `
  -bearerToken $accessToken

Write-Host "  Generating .databrickscfg" -ForegroundColor DarkYellow
Set-Content ~/.databrickscfg "[DEFAULT]"
Add-Content ~/.databrickscfg "host = https://$workspaceUrl"
Add-Content ~/.databrickscfg "token = $token"
Add-Content ~/.databrickscfg ""

###############################################################################################
# Stop all jobs and reset schedule
###############################################################################################
Write-Host "Stop all jobs and reset schedule" -ForegroundColor DarkGreen

Write-Host "  Reset schedule on all jobs" -ForegroundColor DarkYellow
Reset-Schedule-On-All-DatabricksJob

Write-Host "  Stop all jobs" -ForegroundColor DarkYellow
Stop-All-DatabricksJob

###############################################################################################
# Publish Databricks Notebooks
###############################################################################################
Write-Host "Publish Databricks Notebooks" -ForegroundColor DarkGreen

$notebookPath = "$PSScriptRoot/../../notebooks"
databricks workspace import_dir -o $notebookPath "/"

###############################################################################################
# Deploy Dataplatform Python Library
###############################################################################################
Write-Host "Deploy Dataplatform Python Library" -ForegroundColor DarkGreen

$dataplatformWheelFile = Get-ChildItem "$PSScriptRoot/../../src/dist/data_platform_databricks-1.0-py3-none-any.whl"
$dataplatformWheelPath = "dbfs:/FileStore/jars/python/data_platform_databricks/" + $dataplatformWheelFile.Name

Write-Host "  Moving $($dataplatformWheelFile.FullName) to $($dataplatformWheelPath)" -ForegroundColor DarkYellow
databricks fs cp --overwrite $dataplatformWheelFile.FullName $dataplatformWheelPath # Move file to Databricks, overwriting the old version

Write-Host "  Get Databricks Default Cluster" -ForegroundColor DarkYellow
$defaultClusterId = (Get-DatabricksCluster -clusterName "DefaultCluster").cluster_id
Throw-WhenError -output $defaultClusterId

Start-DatabricksCluster -ClusterName "DefaultCluster"

Write-Host "  Install Libraries on DefaultCluster" -ForegroundColor DarkYellow
databricks libraries install --cluster-id $defaultClusterId --whl $dataplatformWheelPath
databricks libraries install --cluster-id $defaultClusterId --maven-coordinates "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18"

Restart-DatabricksCluster -ClusterName "DefaultCluster"

###############################################################################################
# Create Jobs
###############################################################################################
Write-Host "Publish Databricks Jobs" -ForegroundColor DarkGreen

Write-Host "  Setup Databricks Environment Job" -ForegroundColor DarkYellow

New-DatabricksJob `
  -name "Utilities - Setup Environment" `
  -notebookPath "/setup_environment" `
  -clusterId $defaultClusterId `
  -runNow

Include-FilesInFolder "$PSScriptRoot/jobs/"