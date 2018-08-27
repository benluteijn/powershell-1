<#
.SYNOPSIS
Verify all VDI's have AD objects

.DESCRIPTION
This function extracts desktops from AD and VDI's from VMWare view. It compares those two and shows the difference.  

.EXAMPLE
Start-CompareVDIs

.NOTES
Function name:          Show-VMToolsOutdated
Author:                 Dennis Kool 
DateCreated:            26-06-2018
DateModified:           26-06-2018

.NOTES
11-06-2018:             Initial release
#>


function Show-VMToolsOutdated {

    [CmdletBinding()]
    param()

    #set dynamic variables
    Set-Variable `
        -Name file `
        -Value "D:\Scripts\ShowVMToolsOutdated\Output\vmtools-outdated-$((Get-Date).ToString('MM-dd-yyyy')).log"

    #load static variables using json file
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    #get all VM's
    $vm = get-vm | Select-Object `
        -ExpandProperty ExtensionData | Select-Object `
        -ExpandProperty guest 

    $needsupgrade = $vm | Where-Object {
        $_.ToolsVersionStatus `
            -eq "guestToolsNeedUpgrade"} |Select-Object `
        -ExpandProperty Hostname

    $upgrade = foreach ($entry in $needsupgrade) {
        $entry -replace ".nl.kworld.kpmg.com", ""
    }

    foreach ($entry in $upgrade) {
        Write-Verbose "Host $entry needs VMWareTools upgrade"
    }

}