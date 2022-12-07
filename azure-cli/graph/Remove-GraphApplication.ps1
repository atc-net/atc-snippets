function Remove-GraphApplication {
  param (
    [Parameter(Mandatory = $true)]
    [string]
    $appId
  )

  az rest `
    --method delete `
    --url https://graph.microsoft.com/v1.0/applications/$appId

}
