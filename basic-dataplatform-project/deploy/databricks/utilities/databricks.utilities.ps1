function New-DatabricksJob {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $notebookPath,

    [Parameter(Mandatory=$false)]
    [object]
    $notebookParameters = @{},

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
    notebook_task        = @{
      revision_timestamp = 0
      notebook_path      = $notebookPath
      base_parameters    = $notebookParameters
    }
    email_notifications  = @{ }
    libraries            = $libraries
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

  Write-Host "    Creating job with name '$name'"

  $jobs = ((databricks jobs list --output JSON | ConvertFrom-Json -Depth 99).jobs) | Where-Object { $_.settings.name -eq $name }
  if ($jobs.Count -eq 0) {
    $jobId = ((databricks jobs create --json-file ./job.json) | ConvertFrom-Json).job_id
  }
  else {
    Write-Host "    Found an existing job with name '$name'; overwriting it"
    $jobId = $jobs[0].job_id;
    databricks jobs reset --job-id $jobId --json-file ./job.json
  }

  Write-Host (Get-Content -Path ./job.json) -ForegroundColor DarkCyan

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

function Stop-All-DatabricksJob {
  param (
  )

  $jobs = ((databricks jobs list --output JSON | ConvertFrom-Json -Depth 99).jobs)

  foreach ($job in $jobs) {
    $jobId = $job.job_id
    $jobName = $job.settings.name

    Stop-DatabricksJob -jobId $jobId -name $jobName
  }
}

function Reset-Schedule-On-All-DatabricksJob {
  param (
  )

  $jobs = ((databricks jobs list --output JSON | ConvertFrom-Json -Depth 99).jobs)

  foreach ($job in $jobs) {
    $jobId = $job.job_id
    $jobName = $job.settings.name

    $newJob = $job.settings
    $newJob.PSObject.properties.remove('schedule')

    Set-Content ./job.json ($newJob | ConvertTo-Json -Depth 4)
    Write-Host "    Ressting schedule for $jobName job"
    $output = databricks jobs reset --job-id $jobId --json-file ./job.json
    Throw-WhenError -output $output
    Remove-Item ./job.json
  }
}

function Wait-For-DatabricksRun-To-Stop {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $runId,

    [Parameter(Mandatory = $false)]
    [int]
    $pollIntervalInSeconds = 5
  )

  $state_message = ""
  $result_state = ""
  do {
    $run = (databricks runs get --run-id $runId) | ConvertFrom-Json

    if ($state_message -ne $run.state.state_message) {
      $state_message = $run.state.state_message
      if ($state_message) {
        Write-Host "      Job state: $state_message" -ForegroundColor Cyan
      }
    }

    Write-Host "      No new state found, waiting $pollIntervalInSeconds before polling again ..." -ForegroundColor DarkGray
    Start-Sleep -Seconds $pollIntervalInSeconds
    $result_state = $run.state.result_state
  } until ($result_state)

  Write-Host "      Job result: $result_state" -ForegroundColor Cyan
}

Function Get-DatabricksCluster {
  param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterName
  )

  if (($clusterId -eq "") -and ($clusterName -eq "")) {
    Write-Error "Either clusterId and clusterName needs to be provided."
    throw
  }

  if (($clusterId -ne "") -and ($clusterName -ne "")) {
    Write-Error "Provide either clusterId or clusterName - not both."
    throw
  }

  if ($clusterId) {
    $clusters = ((databricks clusters list --output JSON | ConvertFrom-Json).clusters) | Where-Object { $_.cluster_id -eq $clusterId }

    if ($clusters.Count -eq 0) {
      Throw-WhenError -output "Cluster with id $clusterId does not exist"
    }
  }
  else {
    $clusters = ((databricks clusters list --output JSON | ConvertFrom-Json).clusters) | Where-Object { $_.cluster_name -eq $clusterName }

    if ($clusters.Count -eq 0) {
      Throw-WhenError -output "Cluster with name $clusterName does not exist"
    }
  }

  return $clusters[0]
}

Function Start-DatabricksCluster {
  param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterName
  )

  if (($clusterId -eq "") -and ($clusterName -eq "")) {
    Write-Error "Either clusterId and clusterName needs to be provided."
    throw
  }

  if (($clusterId -ne "") -and ($clusterName -ne "")) {
    Write-Error "Provide either clusterId or clusterName - not both."
    throw
  }

  if ($clusterId) {
    $cluster = Get-DatabricksCluster -clusterId $clusterId
  }
  else {
    $cluster = Get-DatabricksCluster -clusterName $clusterName
  }

  if($cluster.state -eq "TERMINATED")
  {
    Write-Host "    Starting cluster: $($cluster.cluster_name)"
    databricks clusters start --cluster-id $cluster.cluster_id
    Start-Sleep -s 5
    Wait-For-DatabricksCluster-To-Start -clusterId $cluster.cluster_id
  }
}

Function Restart-DatabricksCluster {
  param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterName
  )

  if (($clusterId -eq "") -and ($clusterName -eq "")) {
    Write-Error "Either clusterId and clusterName needs to be provided."
    throw
  }

  if (($clusterId -ne "") -and ($clusterName -ne "")) {
    Write-Error "Provide either clusterId or clusterName - not both."
    throw
  }

  if ($clusterId) {
    $cluster = Get-DatabricksCluster -clusterId $clusterId
  }
  else {
    $cluster = Get-DatabricksCluster -clusterName $clusterName
  }

  if($cluster.state -eq "RUNNING")
  {
    Write-Host "    Restarting cluster: $($cluster.cluster_name)"
    databricks clusters restart --cluster-id $cluster.cluster_id
    Start-Sleep -s 5
    Wait-For-DatabricksCluster-To-Start -clusterId $cluster.cluster_id
  }
}

function Wait-For-DatabricksCluster-To-Start {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $clusterId,

    [Parameter(Mandatory = $false)]
    [int]
    $pollIntervalInSeconds = 5
  )

  $state = ""
  do {
    $cluster = Get-DatabricksCluster -clusterId $clusterId

    if ($state -ne $cluster.state) {
      $state = $cluster.state
      if ($state) {
        Write-Host "      Cluster state: $state" -ForegroundColor Cyan
      }
    }

    Write-Host "      No new state found, waiting $pollIntervalInSeconds before polling again ..." -ForegroundColor DarkGray
    Start-Sleep -Seconds $pollIntervalInSeconds
  } until ($state -eq "RUNNING")

  Write-Host "      Cluster result: $result_state" -ForegroundColor Cyan
}

function Get-DatabricksInstancePool {
  param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $poolId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $poolName
  )

  if (($poolId -eq "") -and ($poolName -eq "")) {
    Write-Error "Either poolId and poolName needs to be provided."
    throw
  }

  if (($poolId -ne "") -and ($poolName -ne "")) {
    Write-Error "Provide either poolId or poolName - not both."
    throw
  }

  if ($clusterId) {
    $pools = ((databricks instance-pools list --output JSON | ConvertFrom-Json).instance_pools) | Where-Object { $_.instance_pool_id -eq $poolId }

    if ($pools.Count -eq 0) {
      Throw-WhenError -output "Pool with id $poolId does not exist"
    }

    $response = $pools[0]
  }
  else {
    $pools = ((databricks instance-pools list --output JSON | ConvertFrom-Json).instance_pools) | Where-Object { $_.instance_pool_name -eq $poolName }

    if ($pools.Count -eq 0) {
      Throw-WhenError -output "Pool with name $poolName does not exist"
    }

    $response = $pools[0]
  }

  return $response
}