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
    [string]
    $environmentName,

    [Parameter(Mandatory = $true)]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory = $true)]
    [string]
    $systemName,

    [Parameter(Mandatory = $true)]
    [string]
    $serviceAbbreviation,

    [Parameter(Mandatory = $true)]
    [string]
    $serviceName,

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
    -systemAbbreviation $systemAbbreviation `
    -environmentName $environmentName `
    -serviceAbbreviation $serviceAbbreviation `
    -serviceInstance $serviceInstance

  $spnAppIdentityName = Get-AppIdentityDisplayName `
    -type "spn" `
    -systemName $systemName `
    -environmentName $environmentName `
    -serviceName $serviceName `
    -serviceInstance $serviceInstance

  Write-Host "Creating SPN Registration" -ForegroundColor DarkGreen
  $clientId = az ad app create `
    --display-name $spnAppIdentityName `
    --identifier-uris $spnAppIdentityId `
    --query appId

  Write-Host "  Generating SPN secret (Client App ID: $clientId)" -ForegroundColor DarkYellow
  $clientSecret = az ad app credential reset --id $clientId --query password
  $clientSecret = $clientSecret.Remove($clientSecret.Length - 1, 1).Remove(0, 1) # Remove lead/trail quotes

  Write-Host "  Creating Service Principal" -ForegroundColor DarkYellow
  $null = az ad sp create --id $clientId

  $clientIdName = Get-SpnClientIdName `
    -environmentName $environmentName `
    -systemAbbreviation $systemAbbreviation `
    -serviceAbbreviation $serviceAbbreviation `
    -serviceInstance $serviceInstance

  $clientSecretName = Get-SpnClientSecretName `
    -environmentName $environmentName `
    -systemAbbreviation $systemAbbreviation `
    -serviceAbbreviation $serviceAbbreviation `
    -serviceInstance $serviceInstance

  Set-KeyVaultSecretPlain `
    -keyVaultName $envKeyVaultName `
    -resourceGroupName $envResourceGroupName `
    -secretName $clientIdName `
    -secretPlain $clientId

  Set-KeyVaultSecretPlain `
    -keyVaultName $envKeyVaultName `
    -resourceGroupName $envResourceGroupName `
    -secretName $clientSecretName `
    -secretPlain $clientSecret
}