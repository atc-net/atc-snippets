function New-ServiceSPN {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $companyHostName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $envResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $envKeyVaultName,

    [Parameter(Mandatory = $true)]
    [EnvironmentConfig]
    $environmentConfig,

    [Parameter(Mandatory = $true)]
    [NamingConfig]
    $namingConfig,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $serviceInstance = ""
  )

  . "$PSScriptRoot\..\keyvault\get_KeyVaultSecret.ps1"
  . "$PSScriptRoot\..\keyvault\set_KeyVaultSecret.ps1"

  $spnAppIdentityId = Get-AppIdentityUri `
    -type "spn" `
    -companyHostName $companyHostName `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig `
    -serviceInstance $serviceInstance

  $spnAppIdentityName = Get-AppIdentityDisplayName `
    -type "spn" `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig `
    -serviceInstance $serviceInstance

  Write-Host "Creating SPN Registration" -ForegroundColor DarkGreen
  $clientId = az ad app create `
    --display-name $spnAppIdentityName `
    --identifier-uris $spnAppIdentityId `
    --query appId

   $objectId = az ad sp show --id $clientId --query objectId --out tsv

  Write-Host "  Generating SPN secret (Client App ID: $clientId)" -ForegroundColor DarkYellow
  $clientSecret = az ad app credential reset --id $clientId --query password
  $clientSecret = $clientSecret.Remove($clientSecret.Length - 1, 1).Remove(0, 1) # Remove lead/trail quotes

  Write-Host "  Creating Service Principal" -ForegroundColor DarkYellow
  $null = az ad sp create --id $clientId

  $clientIdName = Get-SpnClientIdName `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig `
    -serviceInstance $serviceInstance

  $objectIdName = Get-SpnObjectIdName `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig `
    -serviceInstance $serviceInstance

  $clientSecretName = Get-SpnClientSecretName `
    -environmentConfig $environmentConfig `
    -namingConfig $namingConfig `
    -serviceInstance $serviceInstance

  Set-KeyVaultSecretPlain `
    -keyVaultName $envKeyVaultName `
    -resourceGroupName $envResourceGroupName `
    -secretName $clientIdName `
    -secretPlain $clientId

  Set-KeyVaultSecretPlain `
  -keyVaultName $envKeyVaultName `
  -resourceGroupName $envResourceGroupName `
  -secretName $objectIdName `
  -secretPlain $objectId

  Set-KeyVaultSecretPlain `
    -keyVaultName $envKeyVaultName `
    -resourceGroupName $envResourceGroupName `
    -secretName $clientSecretName `
    -secretPlain $clientSecret
}