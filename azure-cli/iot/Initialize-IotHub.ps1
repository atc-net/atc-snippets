using module "./IotHubSkuNames.psm1"

function Initialize-IotHub {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [string]
    $IotHubName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [ValidateSet([IotHubSkuNames])]
    [string]
    $Sku = "S1",

    [Parameter(Mandatory = $false)]
    [int]
    $NumberOfUnits = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(2, 32)]
    [int]
    $PartitionCount = 4,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 7)]
    [int]
    $RetentionTimeInDays = 7,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]
    $CloudToDeviceMaxAttempts = 10,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 48)]
    [int]
    $CloudToDeviceMessageLifeTimeInHours = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]
    $FeedbackQueueMaximumDeliveryCount = 10,

    [Parameter(Mandatory = $false)]
    [ValidateRange(5, 300)]
    [int]
    $FeedbackQueueLockDurationInSeconds = 60,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 48)]
    [int]
    $FeedbackQueueTimeToLiveInHours = 1,

    [Parameter(Mandatory = $false)]
    [string]
    $Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string[]]
    $ResourceTags = @()
  )

  # import utility functions
  . "$PSScriptRoot\New-IotHub.ps1"
  . "$PSScriptRoot\Update-IotHub.ps1"

  Write-Host "Provision iot hub '$IotHubName'" -ForegroundColor DarkGreen

  Write-Host "  Querying for existing iot hub" -ForegroundColor DarkYellow -NoNewline

  $jmesPath = `
  "[?name=='$IotHubName'] " + `
  "| [0]" + `
  ".{" + `
  "retentionTimeInDays: properties.eventHubEndpoints.events.retentionTimeInDays, " + `
  "cloudToDeviceMessageLifeTimeIso8601: properties.cloudToDevice.defaultTtlAsIso8601, " + `
  "cloudToDeviceMaxAttempts: properties.cloudToDevice.maxDeliveryCount, " + `
  "feedbackQueueMaximumDeliveryCount: properties.cloudToDevice.feedback.maxDeliveryCount, " + `
  "feedbackQueueLockDurationIso8601: properties.cloudToDevice.feedback.lockDurationAsIso8601, " + `
  "feedbackQueueTimeToLiveIso8601: properties.cloudToDevice.feedback.ttlAsIso8601" + `
  "sku: sku.name" + `
  "numberOfUnits: sku.capacity" + `
  "}"

  $iotJson = az iot hub list `
    --resource-group $ResourceGroupName `
    --query $jmesPath

  if ($null -eq $iotJson) {
    Write-Host " -> Resource not found." -ForegroundColor Cyan

    New-IotHub `
      -Name $IotHubName `
      -ResourceGroupName $ResourceGroupName `
      -Sku $Sku `
      -NumberOfUnits $NumberOfUnits `
      -PartitionCount $PartitionCount `
      -RetentionTimeInDays $RetentionTimeInDays `
      -CloudToDeviceMaxAttempts $CloudToDeviceMaxAttempts `
      -CloudToDeviceMessageLifeTimeInHours $CloudToDeviceMessageLifeTimeInHours `
      -FeedbackQueueMaximumDeliveryCount $FeedbackQueueMaximumDeliveryCount `
      -FeedbackQueueLockDurationInSeconds $FeedbackQueueLockDurationInSeconds `
      -FeedbackQueueTimeToLiveInHours $FeedbackQueueTimeToLiveInHours `
      -Location $Location `
      -ResourceTags $ResourceTags
  }
  else {
    $iotResource = $iotJson | ConvertFrom-Json -AsHashtable

    $cloudToDeviceMessageLifeTimeTimespan = [TimeSpan]::Parse($iotResource.cloudToDeviceMessageLifeTimeIso8601)
    $feedbackQueueLockDurationTimespan = [TimeSpan]::Parse($iotResource.feedbackQueueLockDurationIso8601)
    $feedbackQueueTimeToLiveTimespan = [TimeSpan]::Parse($iotResource.feedbackQueueTimeToLiveIso8601)

    if ($iotResource.retentionTimeInDays -ne $RetentionTimeInDays -or
        $cloudToDeviceMessageLifeTimeTimespan.TotalHours -ne $CloudToDeviceMessageLifeTimeInHours -or
        $iotResource.cloudToDeviceMaxAttempts -ne $CloudToDeviceMaxAttempts -or
        $iotResource.feedbackQueueMaximumDeliveryCount -ne $FeedbackQueueMaximumDeliveryCount -or
        $feedbackQueueLockDurationTimespan.TotalSeconds -ne $FeedbackQueueLockDurationInSeconds -or
        $feedbackQueueTimeToLiveTimespan.TotalHours -ne $FeedbackQueueTimeToLiveInHours -or
        $iotResource.sku -ne $Sku -or
        $iotResource.numberOfUnits -ne $NumberOfUnits) {

      Write-Host " -> Resource exists, but changes are detected" -ForegroundColor Cyan

      Update-IotHub `
        -Name $IotHubName `
        -ResourceGroupName $ResourceGroupName `
        -Sku $Sku `
        -NumberOfUnits $NumberOfUnits `
        -RetentionTimeInDays $RetentionTimeInDays `
        -CloudToDeviceMaxAttempts $CloudToDeviceMaxAttempts `
        -CloudToDeviceMessageLifeTimeInHours $CloudToDeviceMessageLifeTimeInHours `
        -FeedbackQueueMaximumDeliveryCount $FeedbackQueueMaximumDeliveryCount `
        -FeedbackQueueLockDurationInSeconds $FeedbackQueueLockDurationInSeconds `
        -FeedbackQueueTimeToLiveInHours $FeedbackQueueTimeToLiveInHours
    }
    else {
      Write-Host " -> Resource exists with desired configuration." -ForegroundColor Cyan
    }
  }
}