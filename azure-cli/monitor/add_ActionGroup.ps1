. "$PSScriptRoot\alert.utilities.ps1"
. "$PSScriptRoot\..\utilities\deploy.utilities.ps1"
. "$PSScriptRoot\..\utilities\deploy.naming.ps1"

class EmailRecipient {
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$Email
}

function Add-ActionGroup {

    param (
        [Parameter(Mandatory = $true)]
        [EnvironmentConfig] $environmentConfig,
      
        [Parameter(Mandatory = $true)]
        [NamingConfig] $namingConfig,

        [Parameter(Mandatory = $true)]
        [object[]] $emailRecipients,

        [Parameter(Mandatory = $false)]
        [string[]] $resourceTags = @()
    )

    #############################################################################################
    # Resource naming section
    #############################################################################################
    $resourceGroupName = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
    $actionGroupName = Get-ResourceGroupName -serviceName $namingConfig.ServiceName -systemName $namingConfig.SystemName -environmentName $environmentConfig.EnvironmentName
    $actionGroupShortName = ($namingConfig.SystemAbbreviation + "-" + $namingConfig.ServiceAbbreviation).ToLower()

    ############################################################################################
    # Action group section
    ############################################################################################
    Write-Host "  Creating action group if not exists" -ForegroundColor DarkYellow

    $output = Get-ActionGroup -resourceGroupName $resourceGroupName -actionGroupName $actionGroupName
    if (!$? -Or $null -eq $output) {
        Write-Host "  Creating..."
        $output = New-ActionGroup -resourceGroupName $resourceGroupName -actionGroupName $actionGroupName -actionGroupShortName $actionGroupShortName -tags $resourceTags
        Throw-WhenError -output $output
    }

    Write-Host "  Adding emails" -ForegroundColor DarkYellow

    foreach ($recipient in $emailRecipients) {
        $action = Get-EmailAction -resourceGroupName $resourceGroupName -actionGroupName $actionGroupName -emailAddress $recipient.Email
        Throw-WhenError -output $action

        if ($action.Count -eq 0){
            Write-Host "    " $recipient.Name -ForegroundColor DarkYellow

            $output = Add-EmailAction -resourceGroupName $resourceGroupName -actionGroupName $actionGroupName -emailName $recipient.Name -emailAddress $recipient.Email
            Throw-WhenError -output $output
        } else {
            Write-Host "    Existing Email Action for $($recipient.Name)" -ForegroundColor DarkYellow
        }
    }
}