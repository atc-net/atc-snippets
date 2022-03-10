function Deploy-AppServicePlan {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('DevTest', 'Production')]
        [string]
        $environmentType = "DevTest",
  
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,
  
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $appServicePlanName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $location = "westeurope",
  
        [Parameter(Mandatory = $false)]
        [string[]] $resourceTags = @()
    )
  
    Write-Host "Provision app service plan '$appServicePlanName'" -ForegroundColor DarkGreen
  
    $sku = 'S1'
    if ($environmentType -eq 'Production') {
        $sku = 'P1V2'
    }
  
    Write-Host "  Querying for existing app service plan" -ForegroundColor DarkYellow -NoNewline
  
    $appServicePlanJson = az appservice plan list `
        --query "[?name=='$($appServicePlanName)'] | [0] .{sku : sku.size, location: location, id: id}"
  
    if ($null -eq $appServicePlanJson) {
        Write-Host " -> Resource not found." -ForegroundColor Cyan
        Write-Host "  Creating app service plan '$appServicePlanName'" -ForegroundColor DarkYellow
        $appServicePlanId = az appservice plan create `
            --name $appServicePlanName `
            --location $location `
            --resource-group $resourceGroupName `
            --sku $sku `
            --tags $resourceTags `
            --query id
  
        Throw-WhenError -output $appServicePlanId
    }
    else {
        $appServicePlanResource = $appServicePlanJson | ConvertFrom-Json -AsHashtable
      
        if ($appServicePlanResource.sku -ne $sku -or 
            $appServicePlanResource.location -ne "West Europe") {
            Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan
            Write-Host "  Updating app service plan '$appServicePlanName'" -ForegroundColor DarkYellow
            $appServicePlanId = az appservice plan update `
                --name $appServicePlanName `
                --resource-group $resourceGroupName `
                --sku $sku `
                --tags $resourceTags `
                --query id
        }
        else {
            Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan
            $appServicePlanId = $appServicePlanResource.id
        }
  
        return $appServicePlanId
    }
}