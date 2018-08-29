<#
.SYNOPSIS
Counts available VDI's per desktop pools

.DESCRIPTION
This function counts the available VDI's per desktop pool.

.EXAMPLE
Show-VdiStats

.NOTES
Function name:          Show-AvailableVDIs
Author:                 Dennis Kool
DateCreated:            11-06-2018
DateModified:           02-08-2018

.NOTES
11-06-2018:             Initial release
12-06-2018:             Excluded VDI's that have maintenance state
18-06-2018:             Added verbose switch
18-06-2018:             Used stream parameter in out-string to have no return carriage in file output
19-06-2018:             Check VDI machines variable before showing differences
06-07-2018:             Added timestamp to verbose logging
31-07-2018:             Added parameter used for output
31-07-2018:             Check file existence before sending output
02-08-2018:             Load static variables from json file
#>



function Show-AvailableVDIs {

    [CmdletBinding()]
    param()

    #set dynamic variables
    Set-Variable `
        -Name file `
        -Value "D:\Scripts\ShowAvailableVDIs\Output\vmware-available-vdi-$((Get-Date).ToString('MM-dd-yyyy')).log"

    #load static variables using json file
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    $hashvm = Import-Clixml -Path "D:\Scripts\Creds\nlsvcvmwa.cred"

    #load module
    If ( ! (Get-Module VMware.Hv.Helper) ) {
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

    If (!($Global:DefaultHVServers)) {
        Write-Verbose "[$(Get-Date)] Could not connect to $hvserver aborting"
        Exit
    }

    #extracting VDI's from VMWare view
    Write-Verbose "[$(Get-Date)] Extracting all VDI's from VMWare Horizon View"
    $vdialldesktops = (Get-HVMachineSummary).base

    #create hastable to get VDI's
    Write-Verbose "[$(Get-Date)] Counting available VDI's per desktop pool"
    $availablevdi = @{
        'NLSUPA' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLSUPA*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLSUPB' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLSUPB*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLREMA' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLREMA*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLREMB' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLREMB*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLKGSA' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLKGSA*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLKGSB' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLKGSB*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLHUNA' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLHUNA*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count

        'NLHUNB' = ($vdialldesktops |Where-Object {
                $_.User -eq $null `
                    -and $_.Name -like "NLHUNB*" `
                    -and $_.BasicState -ne "Maintenance"} |Select-Object `
                -ExpandProperty Name).count
    }

    #write output
    Write-Verbose "[$(Get-Date)] Generating output available VDI's per pool"
    Write-Verbose "[$(Get-Date)] DCA-SUP pool available VDI's: $($availablevdi.nlsupa |Out-String -stream)"
    Write-Verbose "[$(Get-Date)] DCB-SUP pool available VDI's: $($availablevdi.nlsupb |Out-String -stream)"
    Write-Verbose "[$(Get-Date)] DCA-REM pool available VDI's: $($availablevdi.nlrema |Out-String -Stream)"
    Write-Verbose "[$(Get-Date)] DCB-REM pool available VDI's: $($availablevdi.nlremb |Out-String -Stream)"
    Write-Verbose "[$(Get-Date)] DCA-KGS pool available VDI's: $($availablevdi.nlkgsa |Out-String -Stream)"
    Write-Verbose "[$(Get-Date)] DCB-KGS pool available VDI's: $($availablevdi.nlkgsb |Out-String -Stream)"
    Write-Verbose "[$(Get-Date)] DCA-HUN pool available VDI's: $($availablevdi.nlhuna |Out-String -Stream)"
    Write-Verbose "[$(Get-Date)] DCB-HUN pool available VDI's: $($availablevdi.nlhunb |Out-String -Stream)"

}