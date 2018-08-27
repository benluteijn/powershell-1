<#
.SYNOPSIS
Extracts server and share names from DFS namespaces

.DESCRIPTION
This function extracts server and shares from DFS namespaces 

.EXAMPLE
Show-DfsShares -verbose

.NOTES
Function name:          Show-DfsShares
Author:                 Dennis Kool
DateCreated:            27-08-2018
DateModified:           27-08-2018

.NOTES
27-08-2018:             Initial release
#>



function Show-DfsShares {

    [CmdletBinding()]
    param()
 
    #get dfs folder paths through json
    Write-Verbose "[$(Get-Date)] Reading static variables from JSON file"
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    #extracting shares
    Write-Verbose "[$(Get-Date)] Extracting shares from DFS folder paths"
    $FolderList = foreach ($folder in $config.dfsfolderpaths) {get-dfsnfolder -path $folder} 
    $DfsFolderTargets = ForEach ($Folder in $FolderList) { 
        Get-DfsnFolderTarget -Path $Folder.Path 
    }
    $DfsShares = $DfsFolderTargets | Select-Object Path, TargetPath | Sort-Object TargetPath

    write-verbose ($DfsShares | Out-String)

}