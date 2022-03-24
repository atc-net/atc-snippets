class VnetIntegration {
  [Parameter(Mandatory = $true)]
  [string]
  $Vnet

  [Parameter(Mandatory = $true)]
  [string]
  $Subnet

  VnetIntegration([string]$Vnet, [string]$Subnet) {
    $this.Vnet = $Vnet
    $this.Subnet = $Subnet
  }
}