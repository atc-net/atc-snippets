function Set-KeyVaultSPNPolicy {

  param (
    [Parameter(Mandatory = $true)]
    [string]
    $envKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string]
    $keyVaultName,

    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]
    $environmentName,

    [Parameter(Mandatory = $true)]
    [string]
    $systemAbbreviation,

    [Parameter(Mandatory = $true)]
    [string]
    $serviceAbbreviation,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $serviceInstance = ""
  )

  $clientIdName = Get-SpnClientIdName `
    -environmentName $environmentName `
    -systemAbbreviation $systemAbbreviation `
    -serviceAbbreviation $serviceAbbreviation `
    -serviceInstance $serviceInstance

    Write-Host "  Querying $clientIdName secret" -ForegroundColor DarkYellow
    $clientId = az keyvault secret show `
    --name $clientIdName `
    --vault-name $envKeyVaultName `
    --query value `
    --output tsv

    Throw-WhenError -output $clientId

    Write-Host "  Grant access to the spn $clientId" -ForegroundColor DarkYellow
    $output = az keyvault set-policy `
      --name $keyVaultName `
      --resource-group $resourceGroupName `
      --spn $clientId `
      --secret-permissions list get set

    Throw-WhenError -output $output
  }