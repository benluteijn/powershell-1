<#
.SYNOPSIS
Shows azure backup status

.DESCRIPTION
This function extracts all azure subscriptions having backup vaults. It shows all backup jobs within a given time range

.EXAMPLE
Show-AzureBackups -Days -5 -Verbose

.NOTES
Function name:          Show-AzureBackups
Author:                 Dennis Kool
DateCreated:            14-08-2018
DateModified:           14-08-2018

.NOTES
14-08-2018:             Initial release
#>

Function Show-AzureBackups {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Days
    )

    $hashazure = Import-Clixml `
        -Path "D:\Scripts\Creds\azurereadonlya.cred"

    #load static variables using json file
    $config = Get-Content `
        -Path "D:\Scripts\Modules\Config.json" `
        -Raw | ConvertFrom-Json

    #connect to azure
    Write-Verbose "[$(Get-Date)] Connecting to Azure"
    Connect-AzureRmAccount `
        -Credential $hashazure.AzureReadonlya >$null

    Write-Verbose "[$(Get-Date)] Extracting all subscriptions"
    $list = Get-AzureRmSubscription |Select-Object `
        -ExpandProperty Name

    #get subscription ID's having vaults
    $sub = foreach ($sub in $list) {
        Select-AzureRmSubscription `
            -Subscription $sub > $null; Get-AzureRMRecoveryServicesVault | Select-Object `
            -Expandproperty subscriptionid
    }
            
    #translate ID's to subscription names
    $subsvault = foreach ($id in $sub) {
        Get-AzureRmSubscription `
            -SubscriptionId $id | Select-Object `
            -ExpandProperty name
    }

    #get backup status from subscriptions
    Write-Verbose "[$(Get-Date)] Extracting backup status from all vaults"
    $bstatus = foreach ($entry in $subsvault) {
        Select-AzureRmSubscription -subscription $entry >$null; 
        $vault = Get-AzureRMRecoveryServicesVault; 
        Set-AzureRmRecoveryServicesVaultContext `
            -Vault $vault; Get-AzureRMRecoveryServicesBackupJob `
            -from (Get-Date).AddDays($Days).ToUniversalTime() | Select-Object WorkloadName, Operation, Status, StartTime, EndTime | Sort-Object StartTime | Format-Table
    }

    $backupstatus = $bstatus | Out-String
    Write-Verbose $backupstatuss

}