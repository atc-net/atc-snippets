function Deploy-AppServicePlan {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppServicePlanName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('DevTest', 'Production')]
    [string]
    $EnvironmentType = "DevTest",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location = "westeurope",
  
    [Parameter(Mandatory = $false)]
    [string[]] $ResourceTags = @()
  )  
  Write-Host "Provision app service plan '$AppServicePlanName'" -ForegroundColor DarkGreen

  $sku = 'S1'
  if ($EnvironmentType -eq 'Production') {
    $sku = 'P1V2'
  }

  Write-Host "  Querying for existing app service plan" -ForegroundColor DarkYellow -NoNewline

  $appServicePlanJson = az appservice plan list `
    --query "[?name=='$($AppServicePlanName)'] | [0] .{sku : sku.size, location: location, id: id}"

  if ($null -eq $appServicePlanJson) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan
    Write-Host "  Creating app service plan '$AppServicePlanName'" -ForegroundColor DarkYellow
    $appServicePlanId = az appservice plan create `
      --name $AppServicePlanName `
      --location $Location `
      --resource-group $ResourceGroupName `
      --sku $sku `
      --tags $ResourceTags `
      --query id

    Throw-WhenError -output $appServicePlanId
  }
  else {
    $appServicePlanResource = $appServicePlanJson | ConvertFrom-Json -AsHashtable
    
    if ($appServicePlanResource.sku -ne $sku -or $appServicePlanResource.location -ne "West Europe") {
      Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan
      Write-Host "  Updating app service plan '$AppServicePlanName'" -ForegroundColor DarkYellow
      $appServicePlanId = az appservice plan update `
        --name $AppServicePlanName `
        --resource-group $ResourceGroupName `
        --sku $sku `
        --tags $ResourceTags `
        --query id
    }
    else {
      Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan
      $appServicePlanId = $appServicePlanResource.id
    }

    return $appServicePlanId
  }
}