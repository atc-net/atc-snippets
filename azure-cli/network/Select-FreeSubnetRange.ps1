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

  if ($LASTEXITCODE -ne 0) {
    throw $subnets
  }

  Write-Host "Existing subnets:"
  $subnets = $subnets | ConvertFrom-Json | Sort-Object {
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

    # Check if there is enough space between the current and the next subnet to fit the new subnet we want to create.
    if ($nextNetworkAddressUInt32 - $currentBroadcastAddressUInt32 - 1 -ge $requiredAddressCount) {
      # Add 1 to the broadcast address to get the network IP address of a new subnet
      $candidateIpAddressUInt32 = [UInt32]($currentBroadcastAddressUInt32 + 1)
      $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32

      # Ensure that the IP address we found is actually a valid network address.
      # An example of an invalid network address is 192.168.0.1/23
      # It could either be 192.168.0.0/23 or 192.168.2.0/23, but never 192.168.1.0/23
      if ($($candidateIpAddress.Equals($(Get-NetworkIPAddress -IPAddress $candidateIpAddress -SubnetMask $SubnetMask)))) {
        return "$($candidateIpAddress.ToString())/$SubnetMask" 
      }
      else {
        # The candidate we found was not a valid network address.
        # Get the broadcast address of the old candidate and add 1, then we are sure to get the next first valid network address
        # for this subnet mask. 
        # Example: if candidate was 192.168.1.0/23, we get broadcast 192.168.1.255 and add 1 to get 192.168.2.0/23, 
        # which is a valid subnet.
        $broadcastAddress = Get-BroadcastIPAddress -IPAddress $candidateIpAddress -SubnetMask $Subnetmask
        $candidateIpAddressUInt32 = $(ConvertTo-UInt32 -IPAddress $broadcastAddress) + 1

        # Ensure that we are not overlapping into the next subnet after switching to a valid subnet network
        if ($nextNetworkAddressUInt32 - $candidateIpAddressUInt32 -ge $requiredAddressCount) {
          $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32
          return "$($candidateIpAddress.ToString())/$SubnetMask" 
        }
      }
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
  $vnetBroadcastAddressUInt = [UInt32]($vnetNetworkAddressUInt + $vnetIpAddressCount - 1)

  # Get the last subnet from the subnet list, so we can begin the work from where the list ended.
  $lastSubnetCidr = $subnets[$subnets.Count - 1] -split "/"
  $lastSubnetNetworkAddress = [IPAddress]::Parse($lastSubnetCidr[0])
  $lastSubnetMask = [int]::Parse($lastSubnetCidr[1])
  $lastSubnetBroadcastAddress = Get-BroadcastIPAddress -IPAddress $lastSubnetNetworkAddress -SubnetMask $lastSubnetMask
  $lastSubnetBroadcastAddresUInt32 = ConvertTo-UInt32 -IPAddress $lastSubnetBroadcastAddress

  # Add 1 to the last subnet broadcast address to get the network IP address of a potential new subnet
  $candidateIpAddressUInt32 = [UInt32]($lastSubnetBroadcastAddresUInt32 + 1)

  # Check if there is enough space between the candidate IP address and the end of the VNet to fit the new subnet we want to create.
  if ($vnetBroadcastAddressUInt - $candidateIpAddressUInt32 -ge $requiredAddressCount) {
    $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32

    # Ensure that the IP address we found is actually a valid network address.
    # An example of an invalid network address is 192.168.0.1/23.
    # It could either be 192.168.0.0/23 or 192.168.2.0/23, but never 192.168.1.0/23.
    if ($($candidateIpAddress.Equals($(Get-NetworkIPAddress -IPAddress $candidateIpAddress -SubnetMask $SubnetMask)))) {
      return "$($candidateIpAddress.ToString())/$SubnetMask" 
    }
    else {
      # The candidate we found was not a valid network address.
      # Get the broadcast address of the old candidate and add 1, then we are sure to get the next first valid network address
      # for this subnet mask. 
      # Example: if candidate was 192.168.1.0/23, we get broadcast 192.168.1.255 and add 1 to get 192.168.2.0/23, 
      # which is a valid subnet.
      $broadcastAddress = Get-BroadcastIPAddress -IPAddress $candidateIpAddress -SubnetMask $Subnetmask
      $candidateIpAddressUInt32 = $(ConvertTo-UInt32 -IPAddress $broadcastAddress) + 1
      
      # Ensure that we are not going out of bounds of the VNet after switching to a valid subnet network
      if ($vnetBroadcastAddressUInt - $candidateIpAddressUInt32 + 1 -ge $requiredAddressCount) {
        $candidateIpAddress = ConvertTo-IPAddress -IPAddressAsUInt32 $candidateIpAddressUInt32
        return "$($candidateIpAddress.ToString())/$SubnetMask" 
      }
    }
  }

  throw "Unable to find an available subnet range with subnet mask /$SubnetMask in VNet $VnetName $vnetSpace"
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
  $broadcastAddressUint32 = [UInt32]($networkAddressUInt32 + $subnetAddressCount - 1)
  return ConvertTo-IPAddress -IPAddressAsUInt32 $broadcastAddressUint32
}