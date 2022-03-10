. "$PSScriptRoot\alert.utilities.ps1"
. "$PSScriptRoot\..\utilities\deploy.naming.ps1"

function Add-AvailabilityAlerts {

    param (
        [Parameter(Mandatory = $true)]
        [EnvironmentConfig] $environmentConfig,
      
        [Parameter(Mandatory = $true)]
        [NamingConfig] $namingConfig,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $appName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $insightsName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $insightsResourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $domainName
    )

    #############################################################################################
    # Resource naming section
    #############################################################################################
    # Environment Resource Names
    $actionGroupName = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName 
    
    #############################################################################################
    # Alert setup section
    #############################################################################################

    $actionGroup = Get-ActionGroup $insightsResourceGroupName $actionGroupName 
    Throw-WhenError -output $actionGroup

    Write-Host "  Creating ping alert" -ForegroundColor DarkYellow

    $availabilityName = $namingConfig.SystemName + ' ' + $namingConfig.ServiceName + ' ' + 'Availability (Ping)'
    $pingURL = 'https://' + $appName + '.' + $environmentConfig.EnvironmentName + '.' + $domainName
    
    if ($environmentConfig.EnvironmentType -eq "Production") {
        $pingURL = 'https://' + $appName + '.' + $domainName
    }
    $pingURL = $pingURL.ToLower()
    $location = $environmentConfig.Location

    $output = az deployment group create `
        --resource-group $insightsResourceGroupName `
        --template-file "$PSScriptRoot\availability-test.json" `
        --parameters name=$availabilityName `
        --parameters insightsName=$insightsName `
        --parameters insightsResourceGroupName=$insightsResourceGroupName `
        --parameters pingURL=$pingURL `
        --parameters location=$location `
        --parameters pingTestDescription="Monitor availability" `
        --parameters actionGroupName=$actionGroupName

    Throw-WhenError -output $output
}