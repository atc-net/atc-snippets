function Initialize-FunctionApp {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $FunctionAppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppServicePlanId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $AppSettings,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageAccountConnectionString,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $InsightsConnectionString,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [bool]
    $AppServicePlanIsLinux = $false,

    [Parameter(Mandatory = $false)]
    [string]
    $KeyVaultName,

    [Parameter(Mandatory = $false)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [VnetIntegration[]]
    $VnetIntegrations,

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  if ($VnetIntegrations.Count -gt 0 -and -not $SubscriptionId) {
    throw "SubscriptionId is required when VnetIntegrations is set"
  }

  # Import utility functions
  . "$PSScriptRoot\New-FunctionApp.ps1"
  . "$PSScriptRoot\Get-FunctionAppPrincipalId.ps1"
  . "$PSScriptRoot\..\utilities\Get-ConnectionStringValue.ps1"
  . "$PSScriptRoot\..\utilities\Set-AppVnetIntegration.ps1"
  . "$PSScriptRoot\..\utilities\Sync-AppSettings.ps1"
  . "$PSScriptRoot\..\keyvault\Set-KeyVaultSecretPermissions.ps1"

  # Hardcoded values
  $minTlsVersion = "1.2"

  # Dynamically switching between functions version, .NET version and out-of-process/in-process mode would be very difficult to program and maintain.
  # At the time of writing, the newest long term supported .NET is 6.0 and it's best practice to run in isolated mode.
  # This function is hardcoded towards that target.

  Write-Host "Provision Function App '$FunctionAppName'" -ForegroundColor DarkGreen

  #############################################################################################
  # Create Function App if not exists
  #############################################################################################
  Write-Host "  Querying for existing Function App '$FunctionAppName'" -ForegroundColor DarkYellow -NoNewline

  if ($AppServicePlanIsLinux) {
    $linuxFxVersionQuery = "linuxFxVersion: siteConfig.linuxFxVersion, "
    $linuxFxVersion = "dotnet-isolated|6.0"
  }
  else {
    $linuxFxVersionQuery = ""
    $linuxFxVersion = ""
  }

  $jmesPath = `
    "{" + `
    $linuxFxVersionQuery + `
    "use32BitWorkerProcess: siteConfig.use32BitWorkerProcess, " + `
    "minTlsVersion: siteConfig.minTlsVersion" + `
    "}"

  # `az functionapp list` returns null values for all siteConfig properties.
  # We can use `az functionapp show` to get access to the siteConfig properties.
  $functionAppResourceJson = az functionapp show `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --query $jmesPath

  # The `az functionapp show` command will return a non-zero exit code if the functionapp does not exist.
  # We can access and validate that exit code through $LASTEXITCODE
  if ($LASTEXITCODE -ne 0) {
    Write-Host " -> Function app not found" -ForegroundColor Cyan

    $storageAccountName = Get-ConnectionStringValue `
      -Key "AccountName"  `
      -ConnectionString $StorageAccountConnectionString

    New-FunctionApp `
      -Name $FunctionAppName `
      -AppServicePlanId $AppServicePlanId `
      -ResourceGroupName $ResourceGroupName `
      -StorageAccountName $storageAccountName `
      -AppServicePlanIsLinux $AppServicePlanIsLinux `
      -ResourceTags $ResourceTags

    # As with `az functionapp list`, `az functionapp create` returns null values for all siteConfig properties.
    # Therefore we invoke the `az webapp show` query again, to get all the needed info.
    $functionAppResourceJson = az webapp show `
      --name $FunctionAppName `
      --resource-group $ResourceGroupName `
      --query $jmesPath
  }
  else {
    Write-Host "-> Resource exists." -ForegroundColor Cyan
  }

  #############################################################################################
  # Ensure correct siteConfig settings
  #############################################################################################
  Write-Host "  Verifying configuration" -ForegroundColor DarkYellow -NoNewline

  $functionAppResource = $functionAppResourceJson | ConvertFrom-Json -AsHashtable

  if ($functionAppResource.minTlsVersion -ne $minTlsVersion -or
    $functionAppResource.use32BitWorkerProcess -ne $false -or
    $functionAppResource.linuxFxVersion -ne $linuxFxVersion) {
    Write-Host " -> Changes found." -ForegroundColor Cyan

    $linuxOnlyParameters = @()
    if ($AppServicePlanIsLinux) {
      $linuxOnlyParameters += "--linux-fx-version", $linuxFxVersion
    }

    Write-Host "  Updating configuration" -ForegroundColor DarkYellow
    $output = az functionapp config set `
      --name $FunctionAppName `
      --resource-group $ResourceGroupName `
      --min-tls-version $minTlsVersion `
      --ftps-state Disabled `
      --use-32bit-worker-process false `
      @linuxOnlyParameters

    Throw-WhenError -output $output
  }
  else {
    Write-Host " -> Config is valid." -ForegroundColor Cyan
  }

  #############################################################################################
  # Ensure correct AppSettings
  #############################################################################################
  $AppSettings["FUNCTIONS_EXTENSION_VERSION"] = "~4"
  $AppSettings["FUNCTIONS_WORKER_RUNTIME"] = "dotnet-isolated"
  $AppSettings["AzureWebJobsStorage"] = $StorageAccountConnectionString
  $AppSettings["APPLICATIONINSIGHTS_CONNECTION_STRING"] = $InsightsConnectionString

  Sync-AppSettings `
    -FunctionApp `
    -Name $FunctionAppName `
    -AppSettings $AppSettings `
    -ResourceGroupName $ResourceGroupName

  #############################################################################################
  # Configure Vnet Integrations
  #############################################################################################
  if ($VnetIntegrations.Count -gt 0) {
    Set-AppVnetIntegration `
      -FunctionApp `
      -Name $FunctionAppName `
      -VnetIntegrations $VnetIntegrations `
      -SubscriptionId $SubscriptionId `
      -ResourceGroupName $ResourceGroupName

    Throw-WhenError -output $output
  }

  #############################################################################################
  # Configure Key Vault access
  #############################################################################################
  if ($KeyVaultName) {
    $principalId = Get-FunctionAppPrincipalId `
      -Name $FunctionAppName `
      -ResourceGroupName $ResourceGroupName

    Set-KeyVaultSecretPermissions `
      -ObjectId $principalId `
      -SecretPermissions @("get", "list") `
      -KeyVaultName $KeyVaultName `
      -ResourceGroupName $ResourceGroupName
  }
}