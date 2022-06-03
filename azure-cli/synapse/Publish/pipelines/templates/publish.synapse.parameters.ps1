param (
  [Parameter(Mandatory = $True)]
  [ValidateSet("dev", "staging", "prod")]
  [string]
  $EnvironmentName,
      
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]
  $SynapseWorkspaceParameterJsonPath,
      
  [Parameter(Mandatory = $True)]
  [ValidateNotNullOrEmpty()]
  [string]
  $OutputPath,

  [Parameter(Mandatory = $False)]
  [string]
  $ParameterJsonPath
)


. "$PSScriptRoot\Initialize-SynapseParameters.ps1" # Change this to the correct location of the function

# When using Initialize-SynapseParameters
# one can use either use -ReplaceStringValues or -ParameterJsonPath, or both at the same time

# Keep in mind, that -ReplaceStringValues use string replacement, and therefore, introduce risk of overwriting
# parameters which should not be overidden. Furthermore, when iterating over several string replacements (e.g. iteration 1 and iteration2), 
# iteration 2 can alter the previous string replacement that happened in iteration 1. 

$updateParams = @{ 
  cowhdev = "cowh$EnvironmentName"
  #curentvalue  = "replaceValue"
  # ADD YOUR GENERAL PARAMETERS HERE..... 
}
  
Initialize-SynapseParameters `
  -EnvironmentName $EnvironmentName `
  -OutputPath $OutputPath `
  -SynapseWorkspaceParameterJsonPath $SynapseWorkspaceParameterJsonPath `
  -ReplaceStringValues $updateParams `
  -ParameterJsonPath $ParameterJsonPath
