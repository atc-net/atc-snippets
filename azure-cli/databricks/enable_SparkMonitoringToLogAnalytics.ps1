function Enable-SparkMonitoringToLogAnalytics {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$logAnalyticsWorkspaceId,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$logAnalyticsWorkspaceKey,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$subscriptionId,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$resourceGroup,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$resourceName
    )

    (Get-Content "$PSScriptRoot\spark-monitoring.sh" -Raw) `
      -replace "LOG_ANALYTICS_WORKSPACE_ID=","LOG_ANALYTICS_WORKSPACE_ID=$logAnalyticsWorkspaceId" `
      | Set-Content "$PSScriptRoot\spark-monitoring.sh"

    (Get-Content "$PSScriptRoot\spark-monitoring.sh" -Raw) `
      -replace "LOG_ANALYTICS_WORKSPACE_KEY=","LOG_ANALYTICS_WORKSPACE_KEY=$logAnalyticsWorkspaceKey" `
      | Set-Content "$PSScriptRoot\spark-monitoring.sh"

    (Get-Content "$PSScriptRoot\spark-monitoring.sh" -Raw) `
      -replace "AZ_SUBSCRIPTION_ID=","AZ_SUBSCRIPTION_ID=$subscriptionId" `
      | Set-Content "$PSScriptRoot\spark-monitoring.sh"

    (Get-Content "$PSScriptRoot\spark-monitoring.sh" -Raw) `
      -replace "AZ_RSRC_GRP_NAME=","AZ_RSRC_GRP_NAME=""$resourceGroup""" `
      | Set-Content "$PSScriptRoot\spark-monitoring.sh"

    (Get-Content "$PSScriptRoot\spark-monitoring.sh" -Raw) `
      -replace "AZ_RSRC_NAME=","AZ_RSRC_NAME=""$resourceName""" `
      | Set-Content "$PSScriptRoot.\spark-monitoring.sh"

    Write-Host "  Creating spark-monitoring folder in filesystem" -ForegroundColor DarkYellow
    dbfs mkdirs dbfs:/databricks/spark-monitoring

    Write-Host "  Copy inititialization script" -ForegroundColor DarkYellow
    dbfs cp --overwrite "$PSScriptRoot\spark-monitoring.sh" dbfs:/databricks/spark-monitoring/spark-monitoring.sh

    Write-Host "  Copy JAR files" -ForegroundColor DarkYellow
    dbfs cp --overwrite --recursive "$PSScriptRoot\spark-monitoring\" dbfs:/databricks/spark-monitoring/
}
