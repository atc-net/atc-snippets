class DeviceProvisioningServiceAllocationPolicyNames : System.Management.Automation.IValidateSetValuesGenerator {
  [string[]] GetValidValues() {
      return [string[]] ('GeoLatency', 'Hashed')
  }
}