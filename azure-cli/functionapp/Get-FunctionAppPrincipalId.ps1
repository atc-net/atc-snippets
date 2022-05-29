function Get-FunctionAppPrincipalId {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $FunctionAppName,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  $principalId = az functionapp identity show `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --query principalId `
    --output tsv

  Throw-WhenError -output $principalId

  if ($null -eq $principalId) {
    $principalId = az functionapp identity assign `
      --name $FunctionAppName `
      --resource-group $ResourceGroupName `
      --query principalId `
      --output tsv

    Throw-WhenError -output $principalId
  }

  return $principalId
}