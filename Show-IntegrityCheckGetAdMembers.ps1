<#
.SYNOPSIS
This function extracts AD group memberships

.DESCRIPTION
This function extracts AD group memberships

.EXAMPLE
Show-IntegrityCheckGetADMembers -verbose

.NOTES
Function name:          Show-IntegrityCheckGetADMembers
Author:                 Dennis Kool
DateCreated:            17-07-2018
DateModified:           03-08-2018
Reviewed by:
Last review date:

.NOTES
17-07-2018:             Initial release
03-08-2018:             Added switch GenerateOutput
#>

function Show-IntegrityCheckGetADMembers {

    [CmdletBinding()]
    param()

    #set dynamic variables
    Set-Variable `
        -Name file `
        -Value "D:\Scripts\GetADMembers\Output\ad-memberships-$((Get-Date).ToString('MM-dd-yyyy')).log"

    #load static variables using json file
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    #load modules
    If (Get-Module ActiveDirectory) {
        Write-Verbose "[$(Get-Date)] Active directory module already available"
    }
    else {
        Write-Verbose "[$(Get-Date)] Loading active directory module"
        Import-Module ActiveDirectory
    }


    #create list of servers and security groups
    Write-Verbose  "[$(Get-Date)] Extracting existing LAM groups from active directory"
    $Groups = Get-ADGroup -Filter * | Where-Object {
        $_.Name -like $config.ADGroupPrefixLamWildcard} | Select-Object -ExpandProperty Name

    $Table = @()
    $Record = [ordered]@{
        "Group Name"  = ""
        "Name"        = ""
        "objectclass" = ""
    }

    Foreach ($Group in $Groups) {
        $Arrayofmembers = Get-ADGroupMember -Identity $Group | Select-Object Name, ObjectClass

        foreach ($Member in $Arrayofmembers) {
            $Record."Group Name" = $Group
            $Record."Name" = $Member.name
            $Record."ObjectClass" = $Member.objectclass
            $objRecord = New-Object PSObject -property $Record
            $Table += $objrecord
            $Inv = $Table | Out-String
            Write-Verbose $Inv
        }

    }


}




