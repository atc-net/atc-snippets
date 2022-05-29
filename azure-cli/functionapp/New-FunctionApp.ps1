function New-FunctionApp {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $FunctionAppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Plan")]
    [string]
    $AppServicePlanId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageAccountName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [bool]
    $AppServicePlanIsLinux,

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  Write-Host "  Creating Function App '$FunctionAppName'" -ForegroundColor DarkYellow

  if ($AppServicePlanIsLinux) {
    $osType = "Linux"
  }
  else {
    $osType = "Windows"
  }

  $output = az functionapp create `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlanId `
    --storage-account $StorageAccountName `
    --disable-app-insights true `
    --runtime dotnet `
    --runtime-version 6 `
    --functions-version 4 `
    --os-type $osType `
    --tags $resourceTags

  Throw-WhenError -output $output
}
