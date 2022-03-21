function Add-GroupToServicePrincipal(
    [Parameter(Mandatory = $true)]
    [EnvironmentConfig] $environmentConfig,
  
    [Parameter(Mandatory = $true)]
    [NamingConfig] $namingConfig,

    [Parameter(Mandatory = $true)]
    [string] $groupId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $serviceInstance = ""
) {  
    # import utility functions
    . "$PSScriptRoot\..\utilities\deploy.naming.ps1"

    $spnAppIdentityName = Get-AppIdentityDisplayName `
        -type "api" `
        -environmentConfig $environmentConfig `
        -namingConfig $namingConfig `
        -serviceInstance $serviceInstance

    $objectId = az ad sp list --display-name $spnAppIdentityName --query [0].objectId

    Write-Host "Grant group access to Service Principal" -ForegroundColor DarkGreen
    az rest `
        --method POST `
        --url https://graph.microsoft.com/v1.0/servicePrincipals/$objectId/appRoleAssignedTo `
        --headers "Content-Type=application/json" `
        --body "{\""resourceId\"":\""$objectId\"",\""principalId\"":\""$groupId\""}"
}