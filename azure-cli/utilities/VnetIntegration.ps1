class VnetIntegration {
  [Parameter(Mandatory = $true)]
  [string]
  $VnetName

  [Parameter(Mandatory = $true)]
  [string]
  $SubnetName

  VnetIntegration([string]$VnetName, [string]$SubnetName) {
    $this.VnetName = $VnetName
    $this.SubnetName = $SubnetName
  }
}