<#
.SYNOPSIS
Counts available VDI's per desktop pool

.DESCRIPTION
This function counts the available VDI's per desktop pool.

.EXAMPLE
Show-AvailableVDIs -Verbose

.NOTES
Author: Dennis Kool
#>


function Show-AvailableVDIs {

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
                    Server = $hvservers
                    Credential = $hashvm.svcvmwa}
                    Connect-HVServer @params >$null
        }
    } 
    
    else {
        Write-Verbose "[$(Get-Date)] Cannot connect to HV servers"
        break
    }

    #extracting VDI's from VMWare view
    if ([string]::IsNullOrEmpty($pools)) {
        Write-Verbose "[$(Get-Date)] Generating output available VDI's per pool"
            $pools = $config.pools
                foreach ($pool in $pools) {
                    $get = @{
                        PoolName = $pool
                        State = 'AVAILABLE'}
                            $where = @{
                                Filterscript = {$_.namesdata.username -eq $null}
                    }

            foreach ($entry in $pool) {  
                    $summaryCount = @(Get-HVMachineSummary @get | 
                        Where-Object @where).Count
                            Write-Verbose ('{0} available VDIs left at pool {1}' -f $summaryCount, $entry)
            }
        }
    }
}