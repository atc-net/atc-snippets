function Set-WebAppVnetIntegration {
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
    $SubscriptionId,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [Parameter(Mandatory = $true, ParameterSetName = "Multiple")]
    $ResourceGroupName
  )

  begin {
    if ($VnetName) {
      $VnetIntegrations = @([VnetIntegration]::new($VnetName, $SubnetName))
    }
  }
  process {
    $output = az webapp vnet-integration list `
      --name $WebAppName `
      --resource-group $ResourceGroupName `
      --query [].vnetResourceId

    Throw-WhenError -output $output

    $existingVnetIntegrations = $output | ConvertFrom-Json

    foreach ($vnetIntegration in $VnetIntegrations) {
      Write-Host "  Verifying virtual network integration to subnet '$($vnetIntegration.Subnet)' in vnet '$($vnetIntegration.Vnet)'" -ForegroundColor DarkYellow -NoNewline
      $vnetResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualNetworks/$($vnetIntegration.Vnet)/subnets/$($vnetIntegration.Subnet)"

      if ($existingVnetIntegrations -and $existingVnetIntegrations.Contains($vnetResourceId)) {
        Write-Host " -> Integration exists." -ForegroundColor Cyan
      }
      else {
        Write-Host " -> Integration not configured." -ForegroundColor Cyan
        Write-Host "  Adding VNet integration to '$($vnetIntegration.Vnet)', subnet '$($vnetIntegration.Subnet)'" -ForegroundColor DarkYellow
        $output = az webapp vnet-integration add `
          --name $WebAppName `
          --resource-group $ResourceGroupName `
          --subnet $vnetIntegration.Subnet `
          --vnet $vnetIntegration.Vnet

        Throw-WhenError -output $output
      }
    }
  }
}