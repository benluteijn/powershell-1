<#
.SYNOPSIS


.DESCRIPTION


.EXAMPLE
Start-GenerateMail -ModuleCustomIntegrityCheck -Verbose
Start-GenerateMail -ModuleCustomVMWare -Verbose
Start-GenerateMail -ModuleCustomAzure -Verbose

.NOTES
Function name:          Start-GenerateMail
Author:                 Dennis Kool
DateCreated:            14-08-2018
DateModified:           14-08-2018

.NOTES
14-08-2018:             Initial release
#>

Function Start-GenerateMail {


    [CmdletBinding()]
    param(
        [switch] $ModuleCustomIntegrityCheck,
        [switch] $ModuleCustomVMWare,
        [switch] $ModuleCustomAzure
    )

    #load static variables using json file
    Write-Verbose "[$(Get-Date)] Loading data from JSON"
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    if ($ModuleCustomVMWare) {
        Write-Verbose "[$(Get-Date)] Creating array with filenames for manifest module CustomVMWare"
        $file = @("D:\Scripts\ShowAvailableVDIs\Output\vmware-available-vdi-$((Get-Date).ToString('MM-dd-yyyy')).log",
            "D:\Scripts\StartCompareVDIs\Output\vmware-compare-vdi-$((Get-Date).ToString('MM-dd-yyyy')).log")

        Foreach ($entry in $file) {

            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customvmwaremailsubject `
                    -Attachments $entry `
                    -Body "Expected file $entry found on server $env:COMPUTERNAME." `
                    -SmtpServer $config.smtpserver `
                    -Verbose
            }
            else {
                Write-Verbose "[$(Get-Date)] $entry not found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customvmwaremailsubject `
                    -Body "Expected file $entry not found on server $env:COMPUTERNAME. Please investigate" `
                    -SmtpServer $config.smtpserver `
                    -Verbose
            }
        
        }    

    }

    if ($ModuleCustomIntegrityCheck) {
        Write-Verbose "[$(Get-Date)] Creating array with filenames for manifest module CustomIntegrityCheck"
        $file = @("D:\Scripts\Start-IntegrityCheckADGroups\Output\ad-creategroups-$((Get-Date).ToString('MM-dd-yyyy')).log")
    
        Foreach ($entry in $file) {
    
            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customintegritycheckmailsubject `
                    -Attachments $entry `
                    -Body "Expected file $entry found on server $env:COMPUTERNAME." `
                    -SmtpServer $config.smtpserver `
                    -Verbose
            }
            else {
                Write-Verbose "[$(Get-Date)] $entry not found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customintegritycheckmailsubject `
                    -Body "Expected file $entry not found on server $env:COMPUTERNAME. Please investigate" `
                    -SmtpServer $config.smtpserver `
                    -Verbose
           
            }    
    
        }  

    }

    if ($ModuleCustomAzure) {
        Write-Verbose "[$(Get-Date)] Creating array with filenames for manifest module CustomAzure"
        $file = @("D:\Scripts\ShowAzureBackups\Output\azure-backups-$((Get-Date).ToString('MM-dd-yyyy')).log")
    
        Foreach ($entry in $file) {
    
            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customazuremailsubject `
                    -Attachments $entry `
                    -Body "Expected file $entry found on server $env:COMPUTERNAME." `
                    -SmtpServer $config.smtpserver `
                    -Verbose
            }
            else {
                Write-Verbose "[$(Get-Date)] $entry not found. Sending mail"
                Send-MailMessage `
                    -To $config.mailto `
                    -from $config.mailfrom `
                    -Subject $config.customazuremailsubject `
                    -Body "Expected file $entry not found on server $env:COMPUTERNAME. Please investigate" `
                    -SmtpServer $config.smtpserver `
                    -Verbose
           
            }    
    
        }  

    }

}