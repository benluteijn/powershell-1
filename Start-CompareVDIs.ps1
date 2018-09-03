<#
.SYNOPSIS
Verify all VDI's have AD objects

.DESCRIPTION
This function extracts desktops from AD and VDI's from VMWare view. It compares those two and shows the difference.  

.EXAMPLE
Start-CompareVDIs

.NOTES
Function name:          Start-CompareVDIs
Author:                 Dennis Kool 
DateCreated:            11-06-2018
DateModified:           02-08-2018
#>

    

function Start-CompareVDIs {

    [CmdletBinding()]
    param()
 
    if (!($configfile)) {
        Write-Verbose "[$(Get-Date)] Variable configfile not set properly"
        break
    }
    
    else {
        $config = Get-Content `
            -Path $configfile `
            -Raw | ConvertFrom-Json
    }

    if ($env:UserName -eq $config.nlsvcvmwa) {
        Write-Verbose "[$(Get-Date)] Loading credentials"
        $hashvm = Import-Clixml `
            -Path "D:\Scripts\Creds\nlsvcvmwa.cred"
    }
    
    else {
        Write-Verbose "[$(Get-Date)] Run this script as a different user"
        break
    }

    #load module
    If (!(Get-Module VMware.Hv.Helper) ) {
        Write-Verbose "[$(Get-Date)] Loading VMware HV Helper module"
        Import-Module VMware.Hv.Helper
    }
    else {
        Write-Verbose "[$(Get-Date)] VMware HV Helper module already loaded"
    }
  
    #connect to VMWare view environments
    If ($Global:DefaultHVServers) {
        Write-Verbose "[$(Get-Date)] Already connected to HV server"
    }
    else {   
        Write-Verbose "[$(Get-Date)] Connecting to HV server" 
        foreach ($hvservers in $config.hvserver) {
            Connect-HVServer `
                -server $hvservers `
                -Credential $hashvm.svcvmwa >$null
        }
    }

    Write-Verbose "[$(Get-Date)] Extracting desktops from active directory"
    $addesktops = Get-ADComputer `
        -ldapFilter (!($config.ldapfilter)) `
        -SearchBase $config.ouvdi `
        -Properties * | Select-Object `
        -ExpandProperty Name

    If (!($Global:DefaultHVServers)) {
        Write-Verbose "[$(Get-Date)] Could not connect to $hvserver aborting"
        break
    }

    Write-Verbose "[$(Get-Date)] Extracting all VDI's from VMWare Horizon View"
    $vdidesktops = (Get-HVMachineSummary).base | Select-Object `
        -ExpandProperty Name

    If ($vdidesktops -eq $null) {
        Write-Verbose "[$(Get-Date)] Cannot get VDI's from $hvserver aborting"
        break
    }

    #compare
    Write-Verbose "[$(Get-Date)] Comparing existing VDI's against Active Directory"
    Write-Verbose "[$(Get-Date)] Generating output differences VDI's against AD objects"
    $differences = $addesktops | Where-Object {
        $vdidesktops -notcontains $_
    }

    if ($differences) {
        foreach ($difference in $differences) {
            Write-Verbose "[$(Get-Date)] No VDI found for AD object $difference" 
        }
    }
    else {
        Write-Verbose "[$(Get-Date)] All VDI desktops have related AD objects "
    }


}