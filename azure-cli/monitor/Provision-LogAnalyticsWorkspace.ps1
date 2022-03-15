function Provision-LogAnalyticsWorkspace {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $LogAnalyticsName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location = "westeurope",
    
    [Parameter(Mandatory = $false)]
    [string[]] 
    $ResourceTags = @()
  )

  # import utility functions
  . "$PSScriptRoot\New-LogAnalyticsWorkspace.ps1"

  Write-Host "Provision Log Analytics Workspace '$LogAnalyticsName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing Log Analytics Workspace" -ForegroundColor DarkYellow -NoNewline
  $response = az monitor log-analytics workspace list `
    --resource-group $resourceGroupName `
    --query "[?name=='$logAnalyticsName']|[0].{id: id}"

  if ($null -eq $response) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan
        
    $logAnalyticsId = New-LogAnalyticsWorkspace `
      -Name $LogAnalyticsName `
      -ResourceGroupName $ResourceGroupName `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    Write-Host " -> Resource exists." -ForegroundColor Cyan

    $logAnalyticsId = ($response | ConvertFrom-Json -AsHashtable).id
  }
  
  return $logAnalyticsId
}