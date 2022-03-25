function Initialize-WebApp {
  param (
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $WebAppName,

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
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string[]]
    $AllowedOrigins,

    [Parameter(Mandatory = $false)]
    $KeyVaultName,

    [Parameter(Mandatory = $false)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [VnetIntegration[]]
    $VnetIntegrations,

    [Parameter(Mandatory = $false)]
    [string]
    $MinTlsVersion = "1.2",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  if ($VnetIntegrations.Count -gt 0 -and -not $SubscriptionId) {
    throw "SubscriptionId is required when VnetIntegrations is set"
  }

  . "$PSScriptRoot\New-WebApp.ps1"
  . "$PSScriptRoot\Get-WebAppManagedIdentityPrincipalId.ps1"
  . "$PSScriptRoot\Set-WebAppCors.ps1"
  . "$PSScriptRoot\Set-WebAppVnetIntegration.ps1"
  . "$PSScriptRoot\Sync-WebAppSettings.ps1"
  . "$PSScriptRoot\..\keyvault\Set-KeyVaultSecretPermissions.ps1"

  Write-Host "Provision Web App Service '$WebAppName'" -ForegroundColor DarkGreen

  #############################################################################################
  # Create Web App Service if not exists
  #############################################################################################
  Write-Host "  Querying for existing Web App Service '$WebAppName' " -ForegroundColor DarkYellow -NoNewline
  $jmesPath = `
    "{" + `
    "appServicePlanId: appServicePlanId, " + `
    "minTlsVersion: siteConfig.minTlsVersion, " + `
    "use32BitWorkerProcess: siteConfig.use32BitWorkerProcess, " + `
    "ftpsState: siteConfig.ftpsState" + `
    "}"

  # `az webapp list` returns null values for all siteConfig properties.
  # Microsoft has no intention of fixing this. See https://github.com/Azure/azure-cli/issues/21548
  # We use `az webapp show` to get access to the siteConfig properties.
  $webAppResourceJson = az webapp show `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --query $jmesPath

  # The `az webapp show` command will return a non-zero exit code if the web app does not exist.
  # We can access and validate that exit code through $LASTEXITCODE
  if ($LASTEXITCODE -ne 0) {
    New-WebApp `
      -Name $WebAppName `
      -AppServicePlanId $AppServicePlanId `
      -ResourceGroupName $ResourceGroupName `
      -ResourceTags $ResourceTags

    Throw-WhenError -output $output

    # As with `az webapp list`, `az webapp create` returns null values for all siteConfig properties.
    # Therefore we invoke the `az webapp show` query again, to get all the needed info.
    $webAppResourceJson = az webapp show `
      --resource-group $ResourceGroupName `
      --name $WebAppName `
      --query $jmesPath
  }
  else {
    Write-Host "-> Resource exists." -ForegroundColor Cyan
  }

  #############################################################################################
  # Ensure correct siteConfig settings
  #############################################################################################
  Write-Host "  Verifying platform and TLS configuration" -ForegroundColor DarkYellow -NoNewline

  $webAppResource = $webAppResourceJson | ConvertFrom-Json -AsHashtable

  if ($webAppResource.minTlsVersion -ne $minTlsVersion -or
    $webAppResource.use32BitWorkerProcess -ne $false -or
    $webAppResource.ftpsState -ne "Disabled") {
    Write-Host " -> Changes found." -ForegroundColor Cyan
    Write-Host "  Updating general settings" -ForegroundColor DarkYellow
    $output = az webapp config set `
      --name $WebAppName `
      --resource-group $ResourceGroupName `
      --min-tls-version $MinTlsVersion `
      --ftps-state Disabled `
      --use-32bit-worker-process false

    Throw-WhenError -output $output
  }
  else {
    Write-Host " -> Config is valid." -ForegroundColor Cyan
  }

  #############################################################################################
  # Ensure correct AppSettings
  #############################################################################################
  Sync-WebAppSettings `
    -WebAppName $WebAppName `
    -AppSettings $AppSettings `
    -ResourceGroupName $ResourceGroupName

  #############################################################################################
  # Set CORS
  #############################################################################################
  Set-WebAppCors `
    -WebAppName $WebAppName `
    -AllowedOrigins $AllowedOrigins `
    -ResourceGroupName $ResourceGroupName

  #############################################################################################
  # VNet Integrations
  #############################################################################################
  if ($VnetIntegrations.Count -gt 0) {
    Set-WebAppVnetIntegration `
      -VnetIntegrations $VnetIntegrations `
      -SubscriptionId $SubscriptionId `
      -ResourceGroupName $ResourceGroupName
  }

  #############################################################################################
  # Configure Key Vault access
  #############################################################################################
  if ($KeyVaultName) {
    $principalId = Get-WebAppManagedIdentityPrincipalId `
      -WebAppName $WebAppName `
      -ResourceGroupName $ResourceGroupName

    Set-KeyVaultSecretPermissions `
      -ObjectId $principalId `
      -SecretPermissions @("get", "list") `
      -KeyVaultName $KeyVaultName `
      -ResourceGroupName $ResourceGroupName
  }
}