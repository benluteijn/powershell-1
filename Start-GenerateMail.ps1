<#
.SYNOPSIS
General mail template

.DESCRIPTION
This function sends mail based on file output generated by existing modules

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
    if ([string]::IsNullOrEmpty($config)) {
        Write-Verbose "[$(Get-Date)] Setting config file variable"
        $params = @{
            Path = $configfile
            Raw  = $true}
            $config = Get-Content @params |
            ConvertFrom-Json}

    if ($ModuleCustomVMWare) {
        $file = ($config.'outputvmware-available-vdi' +
            "$((Get-Date).ToString('MM-dd-yyyy')).log"),
        ($config.'outputvmware-compare-vdi' +
            "$((Get-Date).ToString('MM-dd-yyyy')).log")
            
        foreach ($entry in $file) {
            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Start-SendMail
            }
        }
            
        else {
            Write-Verbose "[$(Get-Date)] $entry not found."
        }
    }
    
    if ($ModuleCustomIntegrityCheck) {
        $file = ($config.'outputIntegrityCheck-ad-creategroups' +
            "$((Get-Date).ToString('MM-dd-yyyy')).log")
 
        foreach ($entry in $file) {
            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Start-SendMail
            }
        }
            
        else {
            Write-Verbose "[$(Get-Date)] $entry not found."
        }
    }

    if ($ModuleCustomAzure) {
        $file = ($config.'outputazure-backups' +
            "$((Get-Date).ToString('MM-dd-yyyy')).log")

        foreach ($entry in $file) {
            $existfile = Test-Path -Path $entry
            if ($existfile -eq "True") {
                Write-Verbose "[$(Get-Date)] $entry found. Sending mail"
                Start-SendMail
            }   
            
            else {
                Write-Verbose "[$(Get-Date)] $entry not found."
            }
        }
    }

    Function Start-SendMail {
        $params = @{
            To = $config.mailto
            From = $config.mailfrom
            Subject = $config.mailsubject
            Attachments = $entry
            Body = "Expected file $entry found on server $env:COMPUTERNAME"
            Smtpserver = $config.smtpserver
            Verbose = $true}
            Send-MailMessage @params
    }
}