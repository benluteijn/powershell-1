<#
.SYNOPSIS
Shows active VDIs in VMWAre view

.DESCRIPTION
This function gets active VDIs in VMWAre view 
together with AD attributes

.EXAMPLE
Show-OverviewVDIs -verbose

.NOTES
Author: Dennis Kool
#>

function Show-OverviewVDIs {

    [CmdletBinding()]
    param()

    
    #load static variables using json file
    if ([string]::IsNullOrEmpty($config)) {
        Write-Verbose "[$(Get-Date)] Loading JSON file"
        $params = @{
            Path = $configfile
            Raw  = $true}
            $config = Get-Content @params |
            ConvertFrom-Json
    }

    #load credentials
    if ($env:UserName -eq $config.nlsvcvmwa) {
        Write-Verbose "[$(Get-Date)] Loading credentials"
        $params = @{
            Path = "D:\Scripts\Creds\nlsvcvmwa.cred"}
            $hashvm = Import-Clixml @params
    }

    else {
        Write-Verbose "[$(Get-Date)] Failure loading credentials"
        break
    }

    #load module
    if (!(Get-Module VMware.Hv.Helper)) {
        Write-Verbose "[$(Get-Date)] Loading VMware HV Helper module"
        Import-Module VMware.Hv.Helper
    }

    #connect to VMWare view environments
    if (!($Global:DefaultHVServers)) {
        Write-Verbose "[$(Get-Date)] Connecting to HV server"
        foreach ($hvservers in $config.hvserver) {
            $params = @{
                Server     = $hvservers
                Credential = $hashvm.svcvmwa}
                Connect-HVServer @params >$null
        }
    } 

    else {
        Write-Verbose "[$(Get-Date)] Cannot connect to HV servers"
        break
    }

    if ([string]::IsNullOrEmpty($vms)) {
        $where = @{
            Filterscript = {$_.base.User -ne $null -and 
                $_.namesdata.desktopname -notlike "*uan*"}}
                $vms = Get-HVMachineSummary | Where-Object @where
                $results = @()    
                    foreach ($vm in $vms) {
                        $vmssstemp = $vm.namesdata.username -replace 
                        $config.fqdn, "" 
                        $vmsss = foreach ($entry in $vmssstemp) {
                        $params = @{
                            Filter = {sAMAccountName -eq $entry -and enabled -eq $true}}
                                Get-Aduser @params | select -ExpandProperty name}
                                    
                        foreach ($user in $vmsss) {
                            $params = @{
                            Identity = $user
                            Properties = "Description", "Extensionattribute1", "Extensionattribute9"}
                                $aduser = Get-ADUser @params                  
                                $properties = [ordered]@{
                                    "VDI - Name" = $vm.base.name
                                    "VDI - Poolname" = $vm.namesdata.desktopname
                                    "AD - User" = $vmsss
                                    "AD - Desription" = $aduser.DESCRIPTION
                                    "AD - extensionattribute1" = $aduser.extensionattribute1
                                    "AD - extensionattribute9" = $aduser.extensionattribute9}
                                        $results += new-object psobject -Property $properties

            }   
        }
    }
}