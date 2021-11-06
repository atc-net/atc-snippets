Write-Host "  Get Databricks Default Pool" -ForegroundColor DarkYellow
$defaultPoolId = (Get-DatabricksInstancePool -poolName "DefaultPool").instance_pool_id
Throw-WhenError -output $defaultPoolId

Write-Host "  Setup Databricks Landigzone Jobs" -ForegroundColor DarkYellow

New-DatabricksJob `
  -name "Landigzone - Example job" `
  -notebookPath "/landingzone/exempleOfEltExecution" `
  -numberOfWorkers 0 `
  -timeoutSeconds 3600 `
  -clusterPoolId $defaultPoolId `
  -libraries @(
    @{ maven = @{ coordinates = "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18" } }
    @{ whl = $dataplatformWheelPath }
  ) `
  -cronExpression "0 0 0 * * ?" <# At 00:00 #>