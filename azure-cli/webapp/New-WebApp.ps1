function New-WebApp {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "AppName")]
    [string]
    $WebAppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Plan")]
    [string]
    $AppServicePlanId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]
    $Runtime = "DOTNET:6.0",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  Write-Host "  Creating Web App Service '$WebAppName'" -ForegroundColor DarkYellow

  $output = az webapp create `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlanId `
    --runtime $Runtime `
    --tags $ResourceTags

  Throw-WhenError -output $output
}
