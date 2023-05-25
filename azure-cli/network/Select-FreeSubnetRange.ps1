function Select-FreeSubnetRange {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(2, 29)]
    [int]
    $SubnetMask,

    [Parameter(Mandatory = $true)]
    [string]
    $VnetName,

    [Parameter(Mandatory = $true)]
    [string]
    $ResourceGroupName
  )

  $subnets = az network vnet subnet list `
    --resource-group $ResourceGroupName `
    --vnet-name $VnetName `
    --query "[].addressPrefix"

  $subnets = $subnets | ConvertFrom-Json

  # Check if there is any subnets to begin with
  if ($subnets.Count -eq 0) {
    Write-Host "No existing subnets"

    # There is no existing subnets
    # If the asked subnet range is smaller than the VNet's, we can just use the VNet's network IP address with the input subnet mask
    $vnetSpace = az network vnet show `
      --name $VnetName `
      --resource-group $ResourceGroupName `
      --query addressSpace.addressPrefixes[0] `
      --output tsv

    $vnetCidr = $vnetSpace -split "/"

    if ($SubnetMask -lt [int]::Parse($vnetCidr[1])) {
      throw "SubnetMask parameter value '$SubnetMask' requires mores space than what is available in all of VNet '$vnetName'. Use '$($vnetCidr[1])' or higher integer value"
    }

    return "$($vnetCidr[0])/$SubnetMask"
  }

  Write-Host "Existing subnets:"
  $subnets = $subnets | Sort-Object {
    $cidr = $_ -Split "/"
    Write-Host "- $_"
    ConvertTo-UInt32 -IPAddress $([IPAddress]::Parse($cidr[0]))
  }

  $requiredAddressCount = [System.Math]::Pow(2, 32 - $SubnetMask)
  Write-Host "Required address count in new space from input /$SubnetMask is $requiredAddressCount"

  # Loop through all the existing subnets and try to find a valid CIDR block that can fit between two existing subnets
  for ($i = 0; $i -lt $subnets.Count - 1; $i++) {
    # Split the CIDR notation so we have network address and the subnet mask
    $cidr = $subnets[$i] -split "/"

    # Parse the network address to an IPAddress object and the subnet mask to an integer
    $currentNetworkAddress = [IPAddress]::Parse($cidr[0])
    $currentSubnetMask = [int]::Parse($cidr[1])

    # Calculate the broadcast address for this current subnet.
    # The broadcast address is the highest IP address in the scope.
    $currentBroadcastAddress = Get-BroadcastIPAddress -IPAddress $currentNetworkAddress -SubnetMask $currentSubnetMask

    # Convert the broadcast address to a unsigned 32 bit integer.
    # All IPv4 addresses are 32 bit integers.
    # Converting the IP addresses to integers allows us to do basic math with the IP addresses and check how far apart they are.
    $currentBroadcastAddressUInt32 = ConvertTo-UInt32 -IPAddress $currentBroadcastAddress

    # Get the next subnet from the ordered subnet list and also convert it to an integer.
    $nextNetworkAddress = $($subnets[$i + 1] -split "/")[0]
    $nextNetworkAddressUInt32 = ConvertTo-UInt32 -IPAddress $nextNetworkAddress

    # Add 1 to the broadcast address to get the network IP address of a new subnet
    $candidateIpAddressUInt32 = $currentBroadcastAddressUInt32 + 1
    $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32

    $boundaryIpAddressUInt32 = $nextNetworkAddressUInt32 - 1
    $boundaryIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $boundaryIpAddressUInt32

    $resultIpAddress = Select-FirstNetworkIPAddressInRange `
      -StartIPAddress $candidateIpAddress `
      -EndIPAddress $boundaryIpAddress `
      -SubnetMask $SubnetMask

    if ($null -ne $resultIpAddress) {
      return "$($resultIpAddress.ToString())/$SubnetMask"
    }
  }

  # We didn't manage to find a gap
  # Get the full available VNet space
  $vnetSpace = az network vnet show `
    --name $VnetName `
    --resource-group $ResourceGroupName `
    --query addressSpace.addressPrefixes[0] `
    --output tsv

  $vnetCidr = $vnetSpace -Split '/'
  $vnetNetworkAddress = [IPAddress]::Parse($vnetCidr[0])
  $vnetNetworkAddressUInt = ConvertTo-UInt32 -IPAddress $vnetNetworkAddress
  $vnetIpAddressCount = [System.Math]::Pow(2, 32 - [int]::Parse($vnetCidr[1]))
  $vnetBroadcastAddressUInt32 = $vnetNetworkAddressUInt + [UInt32]($vnetIpAddressCount - 1)

  # Get the last subnet from the subnet list, so we can begin the work from where the list ended.
  $lastSubnetCidr = $subnets[$subnets.Count - 1] -split "/"
  $lastSubnetNetworkAddress = [IPAddress]::Parse($lastSubnetCidr[0])
  $lastSubnetMask = [int]::Parse($lastSubnetCidr[1])
  $lastSubnetBroadcastAddress = Get-BroadcastIPAddress -IPAddress $lastSubnetNetworkAddress -SubnetMask $lastSubnetMask
  $lastSubnetBroadcastAddresUInt32 = ConvertTo-UInt32 -IPAddress $lastSubnetBroadcastAddress

  # Add 1 to the last subnet broadcast address to get a potentional network IP address for a new subnet
  $candidateIpAddressUInt32 = $lastSubnetBroadcastAddresUInt32 + 1
  $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32

  $boundaryIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $vnetBroadcastAddressUInt32

  $resultIpAddress = Select-FirstNetworkIPAddressInRange `
    -StartIPAddress $candidateIpAddress `
    -EndIPAddress $boundaryIpAddress `
    -SubnetMask $SubnetMask

  if ($null -eq $resultIpAddress) {
    throw "Unable to find an available subnet range with subnet mask /$SubnetMask in VNet $VnetName $vnetSpace"
  }

  return "$($resultIpAddress.ToString())/$SubnetMask"
}

function ConvertTo-UInt32 {
  param (
    [Parameter(Mandatory = $true)]
    [IPAddress]
    $IPAddress
  )
  $ipAddressBytes = $IPAddress.GetAddressBytes()
  [Array]::Reverse($ipAddressBytes)
  return [BitConverter]::ToUInt32($ipAddressBytes)
}

function ConvertTo-IPAddress {
  param (
    [Parameter(Mandatory = $true)]
    [UInt32]
    $IPAddressAsUInt32
  )
  $ipAddressBytes = [BitConverter]::GetBytes($IPAddressAsUInt32)
  [Array]::Reverse($ipAddressBytes)
  return [IPAddress]::new($ipAddressBytes)
}

function Get-NetworkIPAddress {
  param (
    [Parameter(Mandatory = $true)]
    [IPAddress]
    $IPAddress,

    [Parameter(Mandatory = $true)]
    [int]
    $SubnetMask
  )

  $maskBytes = [BitConverter]::GetBytes(0xFFFFFFFFu -shl (32 - $SubnetMask))
  $ipAddressBytes = $IPAddress.GetAddressBytes()
  [Array]::Reverse($ipAddressBytes)

  $networkAddressBytes = [byte[]]::new(4)
  for ($i = 0; $i -lt $ipAddressBytes.Length; $i++) {
    $networkAddressBytes[$i] = $ipAddressBytes[$i] -band $maskBytes[$i]
  }

  [Array]::Reverse($networkAddressBytes)
  return [IPAddress]::new($networkAddressBytes)
}

function Get-BroadcastIPAddress {
  param (
    [Parameter(Mandatory = $true)]
    [IPAddress]
    $IPAddress,

    [Parameter(Mandatory = $true)]
    [int]
    $SubnetMask
  )
  $networkAddress = Get-NetworkIPAddress -IPAddress $IPAddress -SubnetMask $SubnetMask
  $networkAddressUInt32 = ConvertTo-UInt32 -IPAddress $networkAddress
  $subnetAddressCount = [System.Math]::Pow(2, 32 - $SubnetMask)
  $broadcastAddressUInt32 = $networkAddressUInt32 + [UInt32]($subnetAddressCount - 1)
  return ConvertTo-IPAddress -IPAddressAsUInt32 $broadcastAddressUInt32
}

function Select-FirstNetworkIPAddressInRange {
  param (
    [Parameter(Mandatory = $true)]
    [IPAddress]
    $StartIPAddress,

    [Parameter(Mandatory = $true)]
    [IPAddress]
    $EndIPAddress,

    [Parameter(Mandatory = $true)]
    [int]
    $SubnetMask
  )

  $broadcastAddress = Get-BroadcastIPAddress -IPAddress $StartIPAddress -SubnetMask $SubnetMask
  $broadcastAddressUInt32 = ConvertTo-UInt32 -IPAddress $broadcastAddress
  $endIpAddressUInt32 = ConvertTo-UInt32 -IPAddress $EndIPAddress

  # Ensure that there is space for the subnet in the range to begin with
  if ($endIpAddressUInt32 -ge $broadcastAddressUInt32) {

    # Check if the given start IP address is already a valid network address
    if ($($StartIPAddress.Equals($(Get-NetworkIPAddress -IPAddress $StartIPAddress -SubnetMask $SubnetMask)))) {
      return $StartIPAddress
    }

    # The start IP address was not a valid network address, get the next valid network address
    $nextNetworkAddressUInt32 = $broadcastAddressUInt32 + 1
    $nextBroadcastAddressUInt32 = $nextNetworkAddressUInt32 + [UInt32][System.Math]::Pow(2, 32 - $SubnetMask) - 1

    # Ensure that the broadcast address of the new subnet is still within the IP address range.
    if ($endIpAddressUInt32 -ge $nextBroadcastAddressUInt32) {
      return ConvertTo-IPAddress -IPAddressAsUInt32 $nextNetworkAddressUInt32
    }
  }

  return $null
}