function Set-AppVnetIntegration {
  [CmdletBinding(DefaultParameterSetName = "Single")]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [string]
    $VnetName,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [string]
    $SubnetName,

    [Parameter(Mandatory = $true, ParameterSetName = "Multiple")]
    [VnetIntegration[]]
    $VnetIntegrations,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [Parameter(Mandatory = $true, ParameterSetName = "Multiple")]
    [Alias("Name")]
    [string]
    $AppName,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [Parameter(Mandatory = $true, ParameterSetName = "Multiple")]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [Parameter(Mandatory = $true, ParameterSetName = "Multiple")]
    [string]
    $ResourceGroupName,

    [Parameter()]
    [switch]
    $WebApp,

    [Parameter()]
    [switch]
    $FunctionApp
  )

  begin {
    # If the command is invoked as with the "Single" ParametSet,
    # initialize the VnetIntegrations array from the "Single" parameters to generalize the approach.
    if ($VnetName) {
      $VnetIntegrations = @([VnetIntegration]::new($VnetName, $SubnetName))
    }

    # Get the resource type
    if (($WebApp -and $FunctionApp) -or
        (-not $WebApp -and -not $FunctionApp)) {
      throw "This function needs to invoked with either WebApp or FunctionApp switch parameter"
    }
    elseif ($WebApp) {
      $type = "webapp"
    }
    elseif ($FunctionApp) {
      $type = "functionapp"
    }
  }
  process {
    $output = az $type vnet-integration list `
      --name $AppName `
      --resource-group $ResourceGroupName `
      --query [].vnetResourceId

    Throw-WhenError -output $output

    $existingVnetIntegrations = $output | ConvertFrom-Json

    foreach ($vnetIntegration in $VnetIntegrations) {
      Write-Host "  Verifying virtual network integration to subnet '$($vnetIntegration.SubnetName)' in vnet '$($vnetIntegration.VnetName)'" -ForegroundColor DarkYellow -NoNewline
      $vnetResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualNetworks/$($vnetIntegration.VnetName)/subnets/$($vnetIntegration.SubnetName)"

      if ($existingVnetIntegrations -and $existingVnetIntegrations.Contains($vnetResourceId)) {
        Write-Host " -> Integration exists." -ForegroundColor Cyan
      }
      else {
        Write-Host " -> Integration not configured." -ForegroundColor Cyan

        Write-Host "  Adding VNet integration to '$($vnetIntegration.VnetName)', subnet '$($vnetIntegration.SubnetName)'" -ForegroundColor DarkYellow
        $output = az $type vnet-integration add `
          --name $AppName `
          --resource-group $ResourceGroupName `
          --vnet $vnetIntegration.VnetName `
          --subnet $vnetIntegration.SubnetName

        Throw-WhenError -output $output
      }
    }
  }
}