using module "./IotHubSkuNames.psm1"

function New-IotHub {
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

  Write-Host "  Creating iot hub '$IotHubName'" -ForegroundColor DarkYellow

  $iotHubId = az iot hub create `
    --name $IotHubName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --partition-count $PartitionCount `
    --retention-day $RetentionTimeInDays `
    --c2d-max-delivery-count $CloudToDeviceMaxAttempts `
    --c2d-ttl $CloudToDeviceMessageLifeTimeInHours `
    --feedback-max-delivery-count $FeedbackQueueMaximumDeliveryCount `
    --feedback-lock-duration $FeedbackQueueLockDurationInSeconds `
    --feedback-ttl $FeedbackQueueTimeToLiveInHours `
    --sku $Sku `
    --unit $NumberOfUnits `
    --query id `
    --output tsv

  Throw-WhenError -output $iotHubId

  return $iotHubId
}