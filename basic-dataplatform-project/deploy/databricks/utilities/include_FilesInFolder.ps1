function Include-FilesInFolder {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $folder
    )

    Get-ChildItem "$folder" -Filter *.ps1 |
    Foreach-Object {
        Write-Host "Now including $_" -ForegroundColor Yellow
        try {
            . ("$_")
        }
        catch {
            Write-Host "Error while including PowerShell Script $_"
        }
    }
}