<#
.SYNOPSIS
Extracts server and share names from DFS namespaces

.DESCRIPTION
This function extracts server and shares from DFS namespaces 

.EXAMPLE
Show-DfsShares -verbose

.NOTES
Author: Dennis Kool
DateCreated: 27-08-2018
#>



function Show-DfsShares {

    [CmdletBinding()]
    param()
 
    #load static variables using json file
    if ([string]::IsNullOrEmpty($config)) {
        Write-Verbose "[$(Get-Date)] Settings config file variable"
        $params = @{
            Path = $configfile
            Raw  = $true}
            $config = Get-Content @params |
            ConvertFrom-Json
    }

    #extracting shares
    if ([string]::IsNullOrEmpty($FolderList)) {
        Write-Verbose "[$(Get-Date)] Extracting shares from DFS folder paths"
        $FolderList = foreach ($folder in $config.dfsfolderpaths) {
            $params = @{
                Path = $folder}
                Get-DfsnFolder @params
        }
         
        if ([string]::IsNullOrEmpty($DfsFolderTargets)) {
            $DfsFolderTargets = ForEach ($Folder in $FolderList) { 
                $params = @{
                    Path = $Folder.Path}
                    Get-DfsnFolderTarget @params 
            }
        }
        if ([string]::IsNullOrEmpty($DfsShares)) {
            $DfsShares = $DfsFolderTargets |
                Select-Object Path, TargetPath | Sort-Object TargetPath
                Write-verbose ($DfsShares | Out-String)
        }
    }
}