function Get-WebAppManagedIdentityPrincipalId {
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $WebAppName,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  Write-Host "  Querying Web App Service '$WebAppName' Managed Identity Principal ID" -ForegroundColor DarkYellow -NoNewline
  $principalId = az webapp identity show `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --query principalId `
    --output tsv

  Throw-WhenError -output $principalId

  if ($null -eq $principalId) {
    $principalId = az webapp identity assign `
      --name $WebAppName `
      --resource-group $ResourceGroupName `
      --query principalId `
      --output tsv

    Throw-WhenError -output $principalId
  }

  Write-Host " -> Received '$principalId'." -ForegroundColor Cyan

  return $principalId
}