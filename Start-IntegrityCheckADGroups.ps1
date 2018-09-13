<#
.SYNOPSIS
Creates AD securitygroups related to remote desktop and local
administrator access

.DESCRIPTION
This function creates missing AD security groups using a specific
naming convention. It extracts existing groups from AD and compares
them with all servers.

.EXAMPLE
Start-IntegrityCheckADGroups -verbose

.NOTES
Author: Dennis Kool
DateCreated: 19-04-2018
#>

function Start-IntegrityCheckADGroups {

    [CmdletBinding()]
    param()

    
    #load static variables using json file
    if ([string]::IsNullOrEmpty($config)) {
        Write-Verbose "[$(Get-Date)] Settings config file variable"
        $params = @{
            Path = $configfile
            Raw = $true}
            $config = Get-Content @params |
            ConvertFrom-Json}

    #load credentials
    if ($env:UserName -eq $config.nlsvcintegritych) {
        Write-Verbose "[$(Get-Date)] Loading credentials"
        $params = @{
            Path = "D:\Scripts\Creds\nlsvcintegritych.cred"}
            $hashadcheck = Import-Clixml @params
    }
    
    #load modules
    if (!(Get-Module ActiveDirectory)) {
        Write-Verbose "[$(Get-Date)] Loading active directory module"
        Import-Module ActiveDirectory
    }
    
    #create exception list.
    if ([string]::IsNullOrEmpty($domaincontrollers)) {
        Write-Verbose "[$(Get-Date)] Creating exclusion list"
        $domaincontrollers = $config.domaincontrollers
    }

    if ([string]::IsNullOrEmpty($exclusions)) {
        $params = @{
            Filter = {OperatingSystem -like "Windows Server*" -and
            Description -like "failover*"}} 
            $failover = Get-ADComputer @params |
            Select-Object -ExpandProperty Name
            $exclusions = $domaincontrollers + $failover
    }

    #create list of servers and security groups
    if ([string]::IsNullOrEmpty($ExistingLamGroups)) {
        Write-Verbose "[$(Get-Date)] Extracting existing LAM groups from active directory"
        $params = @{
            Filter = "Name -like '$($config.ADGroupPrefixLamWildcard)'"}
            $ExistingLamGroups = Get-ADGroup @params |
            Select-Object -ExpandProperty Name
            $ExistingLamGroup = $ExistingLamGroups -replace
            $config.ADGroupPrefixLam
    } 
    
    if ([string]::IsNullOrEmpty($ExistingRdpGroups)) {
        Write-Verbose "[$(Get-Date)] Extracting existing RDP groups from active directory"
        $params = @{
            Filter = "Name -like '$($config.ADGroupPrefixRdpWildcard)'"} 
            $ExistingRdpGroups = Get-ADGroup @params |
            Select-Object -ExpandProperty Name
            $ExistingRdpGroup = $ExistingRdpGroups -replace
            $config.ADGroupPrefixRdp
    }

    if ([string]::IsNullOrEmpty($servernames)) {
        Write-Verbose "[$(Get-Date)] Extracting server list from active directory"
        $params = @{
            Filter = {OperatingSystem -like "Windows Server*"}}
            $servernames = Get-ADComputer @params |
            Select-Object -ExpandProperty Name
    }

    #compare and loop through it to create new ADgroups and trim whitespaces
    if ([string]::IsNullOrEmpty($compareLAM)) {
        Write-Verbose "[$(Get-Date)] Comparing existing LAM groups against all servers"
        $compareLAM = $servernames | Where-Object {
        $ExistingLamGroup -notcontains $_.trim() -and 
        $exclusions -notcontains $_.trim()
        }
    }

    #cleanup groups with no existing AD object
    if ([string]::IsNullOrEmpty($cleanupLamGroups)) {
        $cleanupLamGroups = $ExistingLamGroup | Where-Object {
        $servernames -notcontains $_.trim() -and
        $exclusions -notcontains $_.trim()
        }
    }

    if ([string]::IsNullOrEmpty($cleanupRdpGroups)) {
        $cleanupRdpGroups = $ExistingRdpGroup | Where-Object {
        $servernames -notcontains $_.trim() -and
        $exclusions -notcontains $_.trim()
        }
    }

    #compare and loop through it to create new ADgroups and trim whitespaces
    if ([string]::IsNullOrEmpty($compareRDP)) {
        Write-Verbose "[$(Get-Date)] Comparing existing RDP groups against all servers"
        $compareRDP = $servernames | Where-Object {
        $ExistingRdpGroup -notcontains $_.trim() -and
        $exclusions -notcontains $_.trim()
        }
    }

    #create LAM groups
    foreach ($name in $compareLAM) {
        $namel = $config.ADGroupPrefixLam +$name
        Write-Verbose "[$(Get-Date)] Creating LAM security groups $name1"
        $params = @{
            Name = $name1
            Path = $config.ADOU_LAM
            Description = "Local admin group to server $name"
            GroupScope = "Universal" }
            New-ADGroup @params}
  
    #create RDP groups
    foreach ($names in $compareRDP) {
        $namesc = $config.ADGroupPrefixRdp + $names
        Write-Verbose "[$(Get-Date)] Creating RDP security groups $namesc"
        $params = @{
            Name = $namesc
            Path = $config.ADOU_RDP
            Description = "Local RDP group to server $names"
            GroupScope = "Universal" }
            New-ADGroup @params}

    #cleanup groups with no existing AD object
    if ([string]::IsNullOrEmpty($cleanupLamGroups)) {
        Write-Verbose "[$(Get-Date)] Cleanup LAM groups with no existing AD object"
        foreach ($entry in $cleanupLamGroups) {
            $cleanupgroupslam = $config.ADGroupPrefixLam + $entry
            Write-Verbose "[$(Get-Date)] No object found for group $cleanupgroupslam"
            #Remove-ADGroup `
            #-Identity "$ADGroupPrefixLam$entry" `
            #-Credential $hash.domainadmin `
            #-Confirm:$false
        }
    }

    if ([string]::IsNullOrEmpty($cleanupRdpGroups)) {
        Write-Verbose "[$(Get-Date)] Cleanup RDP groups with no existing AD object"
        foreach ($entrys in $cleanupRdpGroups) {
            $cleanupgroupsrdp = $config.ADGroupPrefixRdp + $entrys
            Write-Verbose "[$(Get-Date)] No object found for group $cleanupgroupsrdp"
            #Remove-ADGroup `
            #-Identity "$ADGroupPrefixRdp$entry" `
            #-Credential $hash.domainadmin `
            #-Confirm:$false 
        }
    }
     
}