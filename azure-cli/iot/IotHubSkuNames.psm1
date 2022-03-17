class IotHubSkuNames : System.Management.Automation.IValidateSetValuesGenerator {
  [string[]] GetValidValues() {
      return [string[]] ('F1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3')
  }
}