function New-DatabricksJob {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $notebookPath,

    [Parameter(Mandatory=$false)]
    [object]
    $notebookParameters = @{},

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $wheelPackageName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $wheelEntryPoint,

    [Parameter(Mandatory=$false)]
    [array]
    $libraries = @(),

    [Parameter(Mandatory = $false)]
    [string]
    $cronExpression,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Standard_F4s', 'Standard_DS3_v2', 'Standard_DS4_v2', 'Standard_L4s')]
    [string]
    $clusterNodeType = "Standard_F4s",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterPoolId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sparkVersion = "9.1.x-scala2.12",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [bool]
    $enableElasticDisk = $true,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $numberOfWorkers = 0,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $minWorkers,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $maxWorkers,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $maxConcurrentRuns = 1,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $timeoutSeconds = 3600,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $maxRetries = 1,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $timezoneId = "UTC",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [array]
    $emailRecipient = @(), #@("email1@customer.com", "email2@customer.com")

    [Parameter(Mandatory = $false)]
    [switch]
    $emailNotification = $false,

    [Parameter(Mandatory = $false)]
    [switch]
    $emailNotificationOnFailure,

    [Parameter(Mandatory = $false)]
    [switch]
    $emailNotificationOnStart,

    [Parameter(Mandatory = $false)]
    [switch]
    $emailNotificationOnSuccess,

    [Parameter(Mandatory = $false)]
    [switch]
    $runAsContinuousStreaming = $false,

    [Parameter(Mandatory = $false)]
    [switch]
    $runNow = $false
  )

  $job = @{
    name                 = $name
    max_concurrent_runs  = $maxConcurrentRuns
    timeout_seconds      = $timeoutSeconds
    max_retries          = $maxRetries
    email_notifications  = @{ }
    libraries            = $libraries
  }

  if ($notebookPath) {
    $job.notebook_task = @{
      revision_timestamp = 0
      notebook_path      = $notebookPath
      base_parameters    = $notebookParameters
    }
  }
  
  if ($wheelEntryPoint) {
    $job.python_wheel_task = @{
      package_name        = $wheelPackageName
      entry_point         = $wheelEntryPoint
    }
  }

  if ($runAsContinuousStreaming) {
    $job.max_concurrent_runs = 1
    $job.timeout_seconds = 0
    $job.max_retries = -1
  }

  if ($emailNotification) {
    if ($emailNotificationOnStart) {
      $job.email_notifications.on_start = $emailRecipient
    }
    if ($emailNotificationOnSuccess) {
      $job.email_notifications.on_success = $emailRecipient
    }
    if ($emailNotificationOnFailure) {
      $job.email_notifications.on_failure = $emailRecipient
    }
  }

  if ($clusterId) {
    $job.existing_cluster_id = $clusterId
  } else {
    $environmentVariables = Get-PysparkEnvironmentVariables

    $sparkConfig = Get-SparkConfig

    $customTags = @{
      "JobName"     = $name
      "Notebook"    = $notebookPath
    }

    if ($numberOfWorkers -eq 0) {
      $sparkConfig = $sparkConfig + (Get-SparkConfigSingleNode)
      $customTags = $customTags + (Get-CustomTagsSingleNode)
    }

    $job.new_cluster = @{
      spark_version     = $sparkVersion
      spark_env_vars    = $environmentVariables
      spark_conf        = $sparkConfig
      custom_tags       = $customTags
    }

    if ($minWorkers -gt 0 -And $maxWorkers -gt 1) {
      $job.new_cluster.autoscale = @{
        min_workers = $minWorkers
        max_workers = $maxWorkers
      }
    } else {
      $job.new_cluster.num_workers = $numberOfWorkers
    }

    if ($clusterPoolId) {
      $job.new_cluster.instance_pool_id      = $clusterPoolId
    } else {
      $job.new_cluster.node_type_id          = $clusterNodeType
      $job.new_cluster.enable_elastic_disk   = $enableElasticDisk
    }
  }

  if ($cronExpression) {
    $job.schedule = @{
      timezone_id            = $timezoneId
      quartz_cron_expression = $cronExpression
    }
  }

  Set-Content ./job.json ($job | ConvertTo-Json -Depth 4)

  Write-Host (Get-Content -Path ./job.json) -ForegroundColor DarkCyan

  $jobs = ((databricks jobs list --output JSON | ConvertFrom-Json -Depth 99).jobs) | Where-Object { $_.settings.name -eq $name }
  if ($jobs.Count -eq 0) {
    Write-Host "    Creating $name job" 
    $jobId = ((databricks jobs create --json-file ./job.json) | ConvertFrom-Json).job_id
  }
  else {
    Write-Host "    Updating $name job"
    $jobId = $jobs[0].job_id;
    databricks jobs reset --job-id $jobId --json-file ./job.json
  }

  Remove-Item ./job.json

  if ($runNow) {
    if ($runAsContinuousStreaming) {
      Start-DatabricksJob -jobId $jobId -waitForCompletion $false -restartIfRunning $true
    }
    else {
      Start-DatabricksJob -jobId $jobId
    }
  }
}

function Get-PysparkEnvironmentVariables {
  $vars = @{
    "PYSPARK_PYTHON" = "/databricks/python3/bin/python3"
  }
  $vars
}

function Get-SparkConfig {
  $config = @{
    "spark.sql.streaming.schemaInference"                           = $true;
    "spark.databricks.delta.preview.enabled"                        = $true;
    "spark.databricks.delta.schema.autoMerge.enabled"               = $true;
    "spark.databricks.io.cache.enabled"                             = $true;
    "spark.databricks.delta.merge.repartitionBeforeWrite.enabled"   = $true;
    "spark.scheduler.mode"                                          = "FAIR";
  }
  $config
}

function Get-SparkConfigSingleNode {
  $config = @{
    "spark.databricks.cluster.profile" = "singleNode";
    "spark.master" = "local[*]";
  }
  $config
}

function Get-SparkConfigHighConcurrency {
  $config = @{
    "spark.databricks.acl.dfAclsEnabled"     = "true";
    "spark.databricks.cluster.profile"       = "serverless";
    "spark.databricks.repl.allowedLanguages" = "sql,python";
  }
  $config
}

function Get-CustomTagsSingleNode {
  $customTags = @{
    "ResourceClass" = "SingleNode"
  }
  $customTags
}

function Get-CustomTagsHighConcurrency {
  $customTags = @{
    "ResourceClass" = "Serverless"
  }
  $customTags
}

function Start-DatabricksJob {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $jobId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $false)]
    [bool]
    $restartIfRunning = $false,

    [Parameter(Mandatory = $false)]
    [bool]
    $waitForCompletion = $true,

    [Parameter(Mandatory = $false)]
    [int]
    $pollIntervalInSeconds = 5
  )

  if ($restartIfRunning) {
    Stop-DatabricksJob -jobId $jobId -name $name
  }

  Write-Host "    Starting job: $name"
  $runId = ((databricks jobs run-now --job-id $jobId) | ConvertFrom-Json).run_id

  if ($waitForCompletion) {
    Wait-For-DatabricksRun-To-Stop -runId $runId -pollIntervalInSeconds $pollIntervalInSeconds
  }
}

function Stop-DatabricksJob {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $jobId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $false)]
    [bool]
    $waitForStopping = $true,

    [Parameter(Mandatory = $false)]
    [int]
    $pollIntervalInSeconds = 5
  )

  $runs = ((databricks runs list --job-id $jobId --output JSON | ConvertFrom-Json -Depth 99).runs) | Where-Object { $_.state.life_cycle_state -eq 'RUNNING' }
  if ($runs.Count -gt 0) {
    Write-Host "    Stopping job: $name"
    $runId = $runs[0].run_id;
    databricks runs cancel --run-id $runId

    if ($waitForStopping) {
      Wait-For-DatabricksRun-To-Stop -runId $runId -pollIntervalInSeconds $pollIntervalInSeconds
    }
  }
  else {
    Write-Host "    job: $name is not running"
  }
}

function Stop-All-DatabricksJobs {
  param (
  )

  $jobs = ((databricks jobs list --output JSON | ConvertFrom-Json -Depth 99).jobs)

  foreach ($job in $jobs) {
    $jobId = $job.job_id
    $jobName = $job.settings.name

    Stop-DatabricksJob -jobId $jobId -name $jobName
  }
}

function Reset-All-DatabricksJobs {
  $list = (databricks jobs list --output JSON) | ConvertFrom-Json
  $message = "  Found " + $list.jobs.Length + " job(s)"
  Write-Host $message

  foreach ($job in $list.jobs) {
    $message = "  Deleting Job: " + $job.settings.name + " (ID=" + $job.job_id + ")"
    Write-Host $message

    databricks jobs delete --job-id $job.job_id
  }
}

function Reset-DatabricksJobsByName {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $jobArray
  )

  $list = (databricks jobs list --output JSON) | ConvertFrom-Json
  $message = "  Found " + $list.jobs.Length + " job(s)"
  Write-Host $message

  foreach ($job in $list.jobs) {
    if ($job.settings.name -in $jobArray) {
      $message = "  Deleting Job: " + $job.settings.name + " (ID=" + $job.job_id + ")"
      Write-Host $message

      databricks jobs delete --job-id $job.job_id
    }
  }
}

function New-DatabricksCluster {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [switch]
    $highConcurrency = $false,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Standard_F4s', 'Standard_DS3_v2', 'Standard_DS4_v2', 'Standard_L4s', 'Standard_DS12_v2', 'Standard_DS13_v2', 'Standard_DS14_v2')]
    [string]
    $nodeType = "Standard_L4s",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sparkVersion = "8.1.x-scala2.12",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [bool]
    $enableElasticDisk = $true,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $autoTerminationMinutes = 120,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $minWorkers = 1,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $maxWorkers = 8,

    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [hashtable]
    $environmentVariables = @{}
  )

  Write-Host "    Creating new cluster"

  $pysparkEnvironmentVariables = @{
    "PYSPARK_PYTHON" = "/databricks/python3/bin/python3"
  }

  $cluster = @{
    cluster_name            = $clusterName
    spark_version           = $sparkVersion
    node_type_id            = $nodeType
    driver_node_type_id     = $nodeType
    autotermination_minutes = $autoTerminationMinutes
    enable_elastic_disk     = $enableElasticDisk
    ssh_public_keys         = @()
    init_scripts            = @()
    spark_env_vars          = $pysparkEnvironmentVariables + $environmentVariables
    spark_conf              = @{
      "spark.sql.streaming.schemaInference"             = $true;
      "spark.databricks.delta.preview.enabled"          = $true;
      "spark.databricks.delta.schema.autoMerge.enabled" = $true;
      "spark.databricks.io.cache.enabled"               = $true;
    }
    custom_tags             = @{}
    autoscale               = @{
      min_workers = $minWorkers
      max_workers = $maxWorkers
    }
  }

  if ($highConcurrency) {
    $cluster.spark_conf = @{
      "spark.databricks.cluster.profile"       = "serverless"
      "spark.databricks.repl.allowedLanguages" = "sql,python,r"
    }
    $cluster.custom_tags = @{
      ResourceClass = "Serverless"
    }
  }

  $clusters = ((databricks clusters list --output JSON | ConvertFrom-Json).clusters) | Where-Object { $_.cluster_name -eq $clusterName }

  if ($clusters.Count -eq 0) {
    Set-Content ./cluster.json ($cluster | ConvertTo-Json)

    Write-Host "    Creating $clusterName"
    $clusterId = ((databricks clusters create --json-file ./cluster.json) | ConvertFrom-Json).cluster_id
    Start-Sleep -Seconds 60
    Write-Host "    Created new cluster (ID=$clusterId)"
  }
  else {
    $clusterId = $clusters[0].cluster_id
    Set-Content ./cluster.json ($cluster + @{ cluster_id = $clusterId } | ConvertTo-Json)

    Write-Host "    $clusterName already exists (ID=$clusterId)"
    Write-Host "    Updating $clusterName ID=$clusterId)"

    databricks clusters edit --json-file ./cluster.json

    Write-Host "    Updated cluster (ID=$clusterId)"
  }

  Remove-Item ./cluster.json

  return $clusterId
}

function New-DatabricksLibrary {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $mavenCoordinates,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $pypiPackageName
  )

  if (!$mavenCoordinates -and !$pypiPackageName) {
    Write-Error "You must specify at least either mavenCoordinates or pypyPackageName"
    throw
  }

  $libraries = databricks libraries list --cluster-id $clusterId | ConvertFrom-Json
  if ($libraries.library_statuses.Length -gt 0) {
    foreach ($status in $libraries.library_statuses) {
      if ($mavenCoordinates) {
        if ($status.library.maven.coordinates -eq $mavenCoordinates) {
          Write-Host "  $mavenCoordinates is already installed"
          return
        }
      }
      if ($pypiPackageName) {
        if ($status.library.pypi.package -eq $pypiPackageName) {
          Write-Host "  $pypiPackageName is already installed"
          return
        }
      }
    }
  }

  if ($mavenCoordinates) {
    Write-Host "  Installing Maven coordinates: $mavenCoordinates"
    databricks libraries install --cluster-id $clusterId --maven-coordinates $mavenCoordinates
  }

  if ($pypiPackageName) {
    Write-Host "  Installing PyPI package: $pypiPackageName"
    databricks libraries install --cluster-id $clusterId --pypi-package $pypiPackageName
  }
}

function Revoke-DatabricksPersonalAccessTokens {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $workspaceUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $bearerToken
  )

  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", "Bearer $bearerToken")

  $listResponse = Invoke-RestMethod `
    -Uri "https://$workspaceUrl/api/2.0/token/list" `
    -Method 'GET' `
    -Headers $headers

  foreach ($token_info in $listResponse.token_infos) {
    if ($token_info.comment -ne "SPN Token") {
      continue
    }

    Write-Host "    Revoking token: $token_info"
    $request = @{ token_id = $token_info.token_id }
    $deleteResponse = Invoke-WebRequest `
      -Uri "https://$workspaceUrl/api/2.0/token/delete" `
      -Method 'POST' `
      -Headers $headers `
      -Form $request

    if ($deleteResponse.StatusCode -ne 200) {
      Write-Error "    Unable to revoke token: $token_info ($deleteResponse.StatusDescription)"
    }
  }
}

function Revoke-DatabricksSpnAdminUser {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $workspaceUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $bearerToken,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clientId
  )

  $baseUrl = "https://$workspaceUrl/api/2.0/preview/scim/v2/ServicePrincipals"
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", "Bearer $bearerToken")

  $getUri = $baseUrl + "?filter=applicationId+eq+$clientId"
  $listResponse = Invoke-RestMethod `
    -Uri $getUri `
    -Method 'GET' `
    -Headers $headers

  if ($listResponse.Resources.Length -eq 0) {
    Write-Error "    Unable to retrieve SPN User from Databricks!"
    return
  }

  foreach ($resource in $listResponse.Resources) {
    if ($resource.applicationId -ne $clientId) {
      continue
    }

    Write-Host "    Revoking SPN User: $resource"
    $deleteUri = $baseUrl + "/" + $resource.id
    $deleteResponse = Invoke-WebRequest `
      -Uri $deleteUri `
      -Method 'DELETE' `
      -Headers $headers

    if ($deleteResponse.StatusCode -ne 200) {
      Write-Error "    Unable to revoke SPN Admin User: $resource ($deleteResponse.StatusDescription)"
    }
  }
}

function New-DatabricksInstancePool {

  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Standard_F4s', 'Standard_DS3_v2', 'Standard_DS4_v2', 'Standard_L4s')]
    [string]
    $clusterNodeType = "Standard_L4s",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $autoTerminationMinutes = 60,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [int]
    $minIdleInstances = 1,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [int]
    $maxCapacity,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $sparkVersion = "8.1.x-scala2.12"
  )

  $pool = @{
    instance_pool_name                    = $name
    node_type_id                          = $clusterNodeType
    idle_instance_autotermination_minutes = $autoTerminationMinutes
    min_idle_instances                    = $minIdleInstances
    max_capacity                          = $maxCapacity
    preloaded_spark_versions              = @($sparkVersion)
  }

  Set-Content ./pool.json ($pool | ConvertTo-Json)

  $pools = ((databricks instance-pools list --output JSON | ConvertFrom-Json).instance_pools) | Where-Object { $_.instance_pool_name -eq $name }
  if ($pools.Count -eq 0) {
    Write-Host "  Creating $name instance pool"
    $poolId = ((databricks instance-pools create --json-file ./pool.json | ConvertFrom-Json).instance_pool_id)
    Write-Host "  Created new instance pool (ID=$poolId)"
  }
  else {
    $poolId = $pools[0].instance_pool_id
    Write-Host "  $name instance pool already exists (ID=$poolId)"

    $pool = databricks instance-pools get --instance-pool-id $poolId | ConvertFrom-Json
    $pool.instance_pool_name = $name
    $pool.node_type_id = $clusterNodeType
    $pool.min_idle_instances = $minIdleInstances
    $pool.max_capacity = $maxCapacity
    $pool.preloaded_spark_versions = @($sparkVersion)

    Set-Content ./pool.json ($pool | ConvertTo-Json)
    databricks instance-pools edit --json-file ./pool.json
    Write-Host "  Updated existing instance pool (ID=$poolId)"
  }

  Remove-Item ./pool.json
  return $poolId
}

function Get-DatabricksInstancePool {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name
  )

  $pools = ((databricks instance-pools list --output JSON | ConvertFrom-Json).instance_pools) | Where-Object { $_.instance_pool_name -eq $name }

  if ($pools.Count -eq 0) {
    Throw-WhenError -output "$name does not exist"
  }

  return $pools[0].instance_pool_id
}

function Reset-DatabricksScope {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name
  )

  $json = databricks secrets list-scopes --output JSON | ConvertFrom-Json
  $scopes = $json | Select-Object -expand "scopes" | Select-Object -expand "name"
  if ($scopes -contains $name) {
    Write-Host "  Reset secret scope '$name'" -ForegroundColor DarkYellow
    databricks secrets delete-scope --scope $name
  }
  else {
    Write-Host "  Create secret scope '$name'" -ForegroundColor DarkYellow
  }

  databricks secrets create-scope --scope $name --initial-manage-principal users
}

function New-DatabricksScope {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $keyVaultDns,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $keyVaultResourceId
  )

  $json = databricks secrets list-scopes --output JSON | ConvertFrom-Json
  $scopes = $json | Select-Object -expand "scopes" | Select-Object -expand "name"
  if ($scopes -contains $name) {
    Write-Host "  The scope '$name' already exists" -ForegroundColor DarkYellow
  }
  else {
    Write-Host "  Create secret scope '$name'" -ForegroundColor DarkYellow
    if ($keyVaultDns -and $keyVaultResourceId) {
      databricks secrets create-scope --scope $name --scope-backend-type AZURE_KEYVAULT --resource-id $keyVaultResourceId --dns-name $keyVaultDns --initial-manage-principal users
    }
    else {
      databricks secrets create-scope --scope $name --initial-manage-principal users
    }
  }
}

function Set-DatabricksSecret {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $key,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $value,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scope
  )

  Write-Host "  Set secret '$key' on scope '$scope'" -ForegroundColor DarkYellow
  databricks secrets put --scope $scope --key $key --string-value $value
}

function Copy-DatabricksSecrets {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scope,

    [Parameter(Mandatory = $false)]
    [bool]
    $deleteNonExistent = $false
  )

  Write-Host "  Copy secrets from Key vault '$keyVaultName' to secret scope '$scope'" -ForegroundColor DarkYellow
  $json = az keyvault secret list --vault-name $keyVaultName --subscription $subscriptionId | ConvertFrom-Json
  $new_keys = $json | Select-Object -expand "name"
  foreach ($key in $new_keys) {
    $value = az keyvault secret show --name $key --query "value" --vault-name $keyVaultName --subscription $subscriptionId
    databricks secrets put --scope $scope --key $key --string-value $value
  }
  if ($deleteNonExistent -and ($new_keys.Length -gt 0)) {
    $json = databricks secrets list --scope $scope --output JSON | ConvertFrom-Json
    $old_keys = $json | Select-Object -expand "secrets" | Select-Object -expand "key"
    foreach ($key in $old_keys) {
      if (!($new_keys -contains $key)) {
        databricks secrets delete --scope $scope --key $key
        Write-Host "  Deleted key '$key'"
      }
    }
  }
}

function ClusterUpdateRequired {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $newSettings,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]
    $currentSettings
  )

  $attributesToCheck = @("cluster_name", "spark_version", "node_type_id", "driver_node_type_id", "autotermination_minutes", "enable_elastic_disk", "spark_env_vars", "spark_conf", "custom_tags", "autoscale", "init_scripts")

  foreach ($h in $attributesToCheck) {
    $newValue = $newSettings.Item($h)
    $currentValue = $currentSettings.$h

    if (($newValue.GetType().Name -eq "Hashtable")) {
      foreach ($k in $newValue.Keys) {
        if ($newValue.Item($k) -ne $currentValue.$k) {
          Write-Host "New Setting {$h} {$k}: ${newValue}: ${currentValue}"
          return $true
        }
      }
    }
    else {
      if ($newValue -ne $currentValue) {
        Write-Host "New Setting {$h}: ${newValue}: ${currentValue}"
        return $true
      }
    }
  }
  return $false
}

function Set-DatabricksPermission {
  param (
    [parameter(Mandatory = $false)]
    [string]$BearerToken,

    [parameter(Mandatory = $false)]
    [string]$Region,

    [parameter(Mandatory = $true)]
    [string]$Principal,

    [parameter(Mandatory = $false)]
    [ValidateSet('user_name', 'group_name', 'service_principal_name')]
    [string]$PrincipalType = 'user_name',

    [Parameter(Mandatory = $true)]
    [string]$PermissionLevel,

    [Parameter(Mandatory = $true)]
    [ValidateSet('jobs', 'clusters', 'instance-pools', 'secretScopes')]
    [string]$DatabricksObjectType,

    [Parameter(Mandatory = $true)]
    [string]$DatabricksObjectId
  )

  $Headers = @{"Authorization" = "Bearer $BearerToken" }

  if ($DatabricksObjectType -eq "secretScope") {
    $URI = "https://$Region.azuredatabricks.net/api/2.0/secrets/acls/put"
    $Body = @{scope = $DatabricksObjectId; principal = $Principal; permission = $PermissionLevel } | ConvertTo-Json -Depth 10
    try {
      Write-Verbose $Body
      $Response = Invoke-RestMethod -Method POST -Body $Body -Uri $URI -Headers $Headers
    }
    catch {
      $err = $_.ErrorDetails.Message
      if ($err.Contains('exists')) {
        Write-Verbose $err
      }
      else {
        throw $err
      }
    }
    return $Response
  }
  else {
    $BasePath = "https://$Region.azuredatabricks.net/api/2.0/preview"
    $URI = "$BasePath/permissions/$DatabricksObjectType" + "/$DatabricksObjectId"

    switch ($PrincipalType) {
      "user_name" { $acl = @(@{"user_name" = $Principal; "permission_level" = $PermissionLevel }) }
      "group_name" { $acl = @(@{"group_name" = $Principal; "permission_level" = $PermissionLevel }) }
      "service_principal_name" { $acl = @(@{"service_principal_name" = $Principal; "permission_level" = $PermissionLevel }) }
    }

    $Body = @{"access_control_list" = $acl } | ConvertTo-Json -Depth 10

    Write-Verbose $Body
    $Response = Invoke-RestMethod -Method "Patch" -Body $Body -Uri $URI -Headers $Headers
  }

  return $Response
}

function Get-ClusterPoolName-Compute {
  return "Compute F4s Streaming Databricks"
}

function Get-ClusterPoolName-General {
  return "Standard L4s instances bricks runtime";
}

function Get-DatabricksCluster {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterName
  )

  $clusters = ((databricks clusters list --output JSON | ConvertFrom-Json).clusters) | Where-Object { $_.cluster_name -eq $clusterName }

  if ($clusters.Count -eq 0) {
    Write-Error "$clusterName does not exist"
    throw
  }

  return $clusters[0].cluster_id
}