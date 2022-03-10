. "$PSScriptRoot\alert.utilities.ps1"
. "$PSScriptRoot\..\utilities\deploy.naming.ps1"

function Add-HttpAlerts {

    param (
        [Parameter(Mandatory = $true)]
        [EnvironmentConfig] $environmentConfig,
      
        [Parameter(Mandatory = $true)]
        [NamingConfig] $namingConfig,

        [Parameter(Mandatory = $false)]
        [string[]] $resourceTags = @()
    )

    Write-Host "Creating alerts" -ForegroundColor Blue

    #############################################################################################
    # Resource naming section
    #############################################################################################
    $resourceGroupName = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
    $resourceName = Get-ResourceName -environmentConfig $environmentConfig -namingConfig $namingConfig

    #############################################################################################
    # Alert setup section
    #############################################################################################

    $actionGroup = Get-ActionGroup $resourceGroupName $resourceGroupName 
    Throw-WhenError -output $actionGroup

    $resourceId = Get-ResourceId -resourceGroupName $resourceGroupName -serviceName $resourceName -resourceType 'Microsoft.Web/sites'
    Throw-WhenError -output $resourceId

    Write-Host "  Creating HTTP 4xx alerts" -ForegroundColor DarkYellow

    $metricName = 'Http4xx'
    $condition = az monitor metrics alert condition create `
        --aggregation Average `
        --metric $metricName `
        --op GreaterThan `
        --type dynamic `
        --sensitivity Medium
    Throw-WhenError -output $condition

    $alertName = $namingConfig.SystemName + ' ' + $namingConfig.ServiceName + ' ' + $metricName + ' (Dynamic)' 
    $output = New-Alert $alertName $resourceGroupName $resourceId $condition $actionGroup -tags $resourceTags
    Throw-WhenError -output $output

    #############################################################################################

    Write-Host "  Creating HTTP 5xx alerts" -ForegroundColor DarkYellow

    $metricName = 'Http5xx'
    $condition = az monitor metrics alert condition create `
        --aggregation Average `
        --metric $metricName `
        --op GreaterThan `
        --type dynamic `
        --sensitivity Medium
    Throw-WhenError -output $condition

    $alertName = $namingConfig.SystemName + ' ' + $namingConfig.ServiceName + ' ' + $metricName + ' (Dynamic)' 
    $output = New-Alert $alertName $resourceGroupName $resourceId $condition $actionGroup -tags $resourceTags
    Throw-WhenError -output $output

    #############################################################################################

    Write-Host "  Creating HTTP Response Time alerts" -ForegroundColor DarkYellow

    $metricName = 'HttpResponseTime'
    $condition = az monitor metrics alert condition create `
        --aggregation Average `
        --metric $metricName `
        --op GreaterThan `
        --type dynamic `
        --sensitivity Medium
    Throw-WhenError -output $condition

    $alertName = $namingConfig.SystemName + ' ' + $namingConfig.ServiceName + ' ' + $metricName + ' (Dynamic)' 
    $output = New-Alert $alertName $resourceGroupName $resourceId $condition $actionGroup -tags $resourceTags
    Throw-WhenError -output $output
}