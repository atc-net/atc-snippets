. "$PSScriptRoot\..\utilities\deploy.utilities.ps1"

function New-Topic-Condition
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $dimension,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $threshold
    )

    return az monitor metrics alert condition create `
    -t static `
    --dimension $dimension `
    --aggregation Average `
    --metric "ActiveMessages" `
    --op GreaterThan `
    --threshold $threshold
}

function New-Dimension
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $entity
    )

    return az monitor metrics alert dimension create `
    -n "EntityName" `
    -v $entity
}

function Get-ResourceId {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $serviceName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $resourceType
    )
    $resourceId = az resource show `
        --resource-group $resourceGroupName `
        --name $serviceName `
        --resource-type $resourceType `
        --query id
    return $resourceId.Replace('"','')
}

function New-ActionGroup{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $actionGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $actionGroupShortName,

        [Parameter(Mandatory=$false)]
        [string[]] 
        $tags = @()
    )

    return az monitor action-group create `
        --resource-group $resourceGroupName `
        --name $actionGroupName `
        --short-name $actionGroupShortName `
        --tags $tags
}

function Add-EmailAction{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $actionGroupName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $emailName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $emailAddress
    )

    return az monitor action-group update `
    --resource-group $resourceGroupName `
    --name $actionGroupName `
    --add-action email $emailName $emailAddress 
}

function Get-EmailAction{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $actionGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $emailAddress
    )

    return az monitor action-group show `
        --resource-group $resourceGroupName `
        --name $actionGroupName `
        --query "emailReceivers[?(emailAddress == '$emailAddress')]" `
        | ConvertFrom-Json
}

function Get-AllEmailAction{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $actionGroupName
    )

    return az monitor action-group show `
        --resource-group $resourceGroupName `
        --name $actionGroupName `
        --query "emailReceivers" `
        | ConvertFrom-Json
}

function Get-ActionGroup {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroupName,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $actionGroupName
    )
    
    $resourceId = az monitor action-group show `
        --resource-group $resourceGroupName `
        --name $actionGroupName `
        --query id 

    return $resourceId.Replace('"','')
}

function New-Alert
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $alertName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $condition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $actionGroup,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $frequency = '5m',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $window = '15m',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $severity = 3,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $description = ' ',

        [Parameter(Mandatory=$false)]
        [string[]] 
        $tags = @(),

        [Parameter(Mandatory=$false)]
        [string] 
        $type = 'Microsoft.Web/sites'
    )

    return az monitor metrics alert create `
        --name $alertName `
        --resource-group $resourceGroup `
        --scopes $resourceId `
        --condition $condition `
        --action $actionGroup `
        --evaluation-frequency $frequency `
        --window-size $window `
        --severity $severity `
        --description $description `
        --tags $tags `
        --region 'westeurope' `
        --type $type 
}