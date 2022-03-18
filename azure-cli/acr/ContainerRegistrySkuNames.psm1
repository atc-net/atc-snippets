class ContainerRegistrySkuNames : System.Management.Automation.IValidateSetValuesGenerator {
  [string[]] GetValidValues() {
      return [string[]] ('Basic', 'Classic', 'Premium', 'Standard')
  }
}