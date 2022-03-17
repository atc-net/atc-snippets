using module "./IotHubSkuNames.psm1"

function Update-IotHub {
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
    $FeedbackQueueTimeToLiveInHours = 1
  )

  Write-Host "  Updating iot hub '$DeviceProvisioningServiceName'" -ForegroundColor DarkYellow
  $output = az iot hub update `
    --name $DeviceProvisioningServiceName `
    --resource-group $ResourceGroupName `
    --retention-day $RetentionTimeInDays `
    --c2d-max-delivery-count $CloudToDeviceMaxAttempts `
    --c2d-ttl $CloudToDeviceMessageLifeTimeInHours `
    --feedback-max-delivery-count $FeedbackQueueMaximumDeliveryCount `
    --feedback-lock-duration $FeedbackQueueLockDurationInSeconds `
    --feedback-ttl $FeedbackQueueTimeToLiveInHours `
    --sku $Sku `
    --unit $NumberOfUnits

  Throw-WhenError -output $output
}