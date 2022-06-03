function Initialize-SynapseParameters {
    <#
    .SYNOPSIS
    The function takes a default generated Synapse Workspace Parameter Json file, 
    and returns a parameterized version of the file.
    .Description
    Initialize-SynapseParameters-Replace take the workspace parameter file
    In the function, you provide which parameters that should be parameterized.

    ParameterJsonPath:
    You can create a environment specific parameter file. 
    The file is then used for parameterization. Set UseConfigJson = True.
    Example:
        synapse.staging.parameters.json

    with the following format:
        {
        "StorageAccountParameterA": "https://cowhAstaging.dfs.core.windows.net",
        "StorageAccountParameterB": "https://cowhBstaing.dfs.core.windows.net"
        }

    ReplaceStringValues:
    In the function, you provide which string sequence should be replaced by another
    For example: 
        {
            SomeParameter: "resourcedev"
        }
    is replaced by:
        {
            SomeParameter: "resourcestaging"
        }

    Be aware, that the function is a bit unsafe, since it uses string-replace. 
    Therefore, the function could alter some values that unintentionally contains the value you want to replace.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("dev", "staging", "prod")]
        [string]
        $EnvironmentName,
      
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SynapseWorkspaceParameterJsonPath,
      
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]
        $ReplaceStringValues,

        [Parameter(Mandatory = $false)]
        [string]
        $ParameterJsonPath
    )


    if (-not $ReplaceStringValues -and -not $ParameterJsonPath) { 
        throw "This function needs to invoked with either or both ReplaceStringValues and ParameterJsonPath" 
    }
    
    # Get the Synapse generated Parameters file
    $synapseParameters = Get-Content -Raw $SynapseWorkspaceParameterJsonPath | ConvertFrom-Json -AsHashTable
    
    if ($ReplaceStringValues) {
        Write-Host "Parameterize using replacing..." -ForegroundColor Yellow
    
        # Updates parameters using Replace
        foreach ($parameter in $synapseParameters.parameters.GetEnumerator()) {
            foreach ($updateParam in $ReplaceStringValues.GetEnumerator()) {
                if ($parameter.value.value.Contains($updateParam.Name) ) {
                    
                    $newValue = $parameter.value.value.Replace($updateParam.Name, $updateParam.Value)
                    Write-Host "  Replacing parameter '$($parameter.Name)' value '$($parameter.value.value)' with '$($newValue)'" -ForegroundColor DarkYellow
                    $parameter.value.value = $newValue

                }
            }
        }
    }

    if ($ParameterJsonPath) {
        Write-Host "Parameterize using jsonfile: $ParameterJsonPath" -ForegroundColor Yellow
        $parameterUpdates = Get-Content -Raw $ParameterJsonPath | ConvertFrom-Json -AsHashTable
        
        foreach ($parameter in $parameterUpdates.GetEnumerator()) {
            Write-Host "  Replacing parameter '$($parameter.Name)' value '$($synapseParameters.parameters.$($parameter.Name).value)' with '$($parameter.Value)'" -ForegroundColor DarkYellow
            $synapseParameters.parameters.$($parameter.Name).value = $parameter.Value
        }
    }

    # New re-parameterized file ready for staging and prod
    Write-Host "Saved parameterized workspace file at: $OutputPath"
    $synapseParameters | ConvertTo-Json | Out-File "$($OutputPath)" 
}