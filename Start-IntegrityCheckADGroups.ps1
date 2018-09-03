<#
.SYNOPSIS
Creates AD securitygroups related to remote desktop and local administrator access

.DESCRIPTION
This function creates missing AD security groups using a specific naming convention. It extracts existing groups from AD and compares them with all servers.

.EXAMPLE
Start-IntegrityCheckADGroups

.NOTES
Function name:          Start-IntegrityCheckADGroups
Author:                 Dennis Kool
DateCreated:            19-04-2018
DateModified:           22-05-2018
Reviewed by:            Ben Luteijn
Last review date:       01-05-2018

.NOTES
19-04-2018:             Initial release
#>


function Start-IntegrityCheckADGroups {

    [CmdletBinding()]
    param()

    #load static variables using json file
    if (!($configfile)) {
        Write-Verbose "[$(Get-Date)] Variable configfile not set properly"
        break
    }
        
    else {
        $config = Get-Content `
            -Path $configfile `
            -Raw | ConvertFrom-Json
    }
    
    if ($env:UserName -eq $config.nlsvcintegritych) {
        Write-Verbose "[$(Get-Date)] Loading credentials"
        $hashadcheck = Import-Clixml `
            -Path "D:\Scripts\Creds\nlsvcintegritych.cred"
    }
        
    else {
        Write-Verbose "[$(Get-Date)] Run this script as a different user"
        break
    }

    #load modules
    If (Get-Module ActiveDirectory) {
        Write-Verbose "[$(Get-Date)] Active directory module already available"
    }
    else {
        Write-Verbose "[$(Get-Date)] Loading active directory module"
        Import-Module ActiveDirectory
    }

    #create dynamic exception list
    Write-Verbose "[$(Get-Date)] Creating exception list"
    $domaincontrollers = $config.domaincontrollers

    $Servers = Get-ADComputer `
        -Filter {OperatingSystem -Like "Windows Server*"} `
        -Properties * |select-Object * `
        -expandproperty name

    $failover = $servers | Where-Object {
        $_.description -like "*failover*"} | Select-Object `
        -ExpandProperty Name

    $exception = $domaincontrollers + $failover

    #create list of servers and security groups
    Write-Verbose  "[$(Get-Date)] Extracting existing LAM groups from active directory"
    $ExistingLamGroups = Get-ADGroup `
        -filter * | Where-Object {
        $_.Name -like $config.ADGroupPrefixLamWildcard} | Select-Object `
        -ExpandProperty Name

    Write-Verbose  "[$(Get-Date)] Extracting existing RDP groups from active directory"
    $ExistingRdpGroups = Get-ADGroup `
        -filter * | Where-Object {
        $_.Name -like $config.ADGroupPrefixRdpWildcard} | Select-Object `
        -ExpandProperty Name

    $ExistingLamGroup = foreach ($line in $ExistingLamGroups) {
        $line -replace $config.ADGroupPrefixLam, ""
    }

    $ExistingRdpGroup = foreach ($lines in $ExistingRdpGroups) {
        $lines -replace $config.ADGroupPrefixRdp, ""
    }

    Write-Verbose "[$(Get-Date)] Extracting server list from active directory"
    $servernames = Get-ADComputer `
        -Filter {OperatingSystem -Like "Windows Server*"} `
        -Properties * |select-Object * `
        -expandproperty Name

    #compare and loop through it to create new ADgroups and trim whitespaces
    Write-Verbose "[$(Get-Date)] Comparing existing LAM groups against all servers"
    $compareLAM = $servernames | Where-Object {
        $ExistingLamGroup -notcontains $_.trim() -and `
            $exception -notcontains $_.trim()
    }

    if (!$compareLAM) {
        Write-Verbose "[$(Get-Date)] All servers have corresponding LAM groups"
    }

    #cleanup groups with no existing AD object
    $cleanupLamGroups = $ExistingLamGroup | Where-Object {
        $servernames -notcontains $_.trim() -and `
            $exception -notcontains $_.trim()
    }

    $cleanupRdpGroups = $ExistingRdpGroup | Where-Object {
        $servernames -notcontains $_.trim() -and `
            $exception -notcontains $_.trim()
    }

    #compare and loop through it to create new ADgroups and trim whitespaces
    Write-Verbose "[$(Get-Date)] Comparing existing RDP groups against all servers"
    $compareRDP = $servernames | Where-Object {
        $ExistingRdpGroup -notcontains $_.trim() -and `
            $exception -notcontains $_.trim()
    }

    if (!$compareRDP) {
        Write-Verbose "[$(Get-Date)] All servers have corresponding RDP groups"
    }

    #create LAM groups
    foreach ($name in $compareLAM) {
        $namel = $config.ADGroupPrefixLam + $name
        Write-Verbose "[$(Get-Date)] Creating LAM security groups $namel"
        New-ADGroup `
            -Name $namel `
            -Path $config.ADOU_LAM `
            -Description "Local Admin group to server $name" `
            -Credential $hashadcheck.svcintegritych >$null `
            -GroupScope "Universal" 
   
    }

    #create RDP groups
    foreach ($names in $compareRDP) {
        $namesc = $config.ADGroupPrefixRdp + $names
        New-ADGroup `
            -Name $namesc `
            -Path $config.ADOU_RDP `
            -Description "Local RDP group to server $names" `
            -Credential $hashadcheck.svcintegritych >$null `
            -GroupScope "Universal"
        Write-Verbose "[$(Get-Date)] Creating RDP security groups $namesc"
    }

    #cleanup groups with no existing AD object
    if ($cleanupLamGroups) {
        Write-Verbose "[$(Get-Date)] Cleanup LAM groups with no existing AD object"
        foreach ($entry in $cleanupLamGroups) {
            $cleanupgroupslam = $config.ADGroupPrefixLam + $entry
            #Remove-ADGroup `
            #-Identity "$ADGroupPrefixLam$entry" `
            #-Credential $hash.domainadmin `
            #-Confirm:$false
            Write-Verbose "[$(Get-Date)] No object found for group $cleanupgroupslam"
        }
    }
    else {
        Write-Verbose "[$(Get-Date)] All LAM groups have corresponding AD objects"
    }

    if ($cleanupRdpGroups) {
        Write-Verbose "[$(Get-Date)] Cleanup RDP groups with no existing AD object"
        foreach ($entrys in $cleanupRdpGroups) {
            $cleanupgroupsrdp = $config.ADGroupPrefixRdp + $entrys
            #Remove-ADGroup `
            #-Identity "$ADGroupPrefixRdp$entry" `
            #-Credential $hash.domainadmin `
            #-Confirm:$false
            Write-Verbose "[$(Get-Date)] No object found for group $cleanupgroupsrdp"
        }
    }
    else {
        Write-Verbose "[$(Get-Date)] All RDP groups have corresponding AD objects"
    }
    
    #enforce empty or wrong descriptions LAM groups
    $emptydescrlam = Get-ADGroup `
        -Filter * -Properties * `
        -SearchBase $config.adou_lam | Where-Object {
        $_.name -like $config.adgroupprefixlamwildcard `
            -and $_.description -eq $null `
            -or $_.description -notlike $config.adgroupdescrlam} | Select-Object `
        -ExpandProperty Name
      
    Write-Verbose "[$(Get-Date)] Enforcing descriptions LAM security groups"
    foreach ($entry in $emptydescrlam) {
        $descrnamelam = $entry `
            -replace $config.adgroupprefixlam, ''
        Set-ADGroup `
            -Identity "$entry" `
            -Description "Local Admin group to server $descrnamelam" `
            -GroupScope "Universal"
        Write-Verbose "[$(Get-Date)] Enforing description for group $entry"
    }

    #enforce empty or wrong descriptions RDP groups
    $emptydescrrdp = Get-ADGroup `
        -Filter * -Properties * `
        -SearchBase $config.adou_rdp | Where-Object {
        $_.name -like $config.adgroupprefixrdpwildcard `
            -and $_.description -eq $null `
            -or $_.description -notlike $config.adgroupdescrrdp} | Select-Object `
        -Expandproperty Name

    Write-Verbose "[$(Get-Date)] Enforcing descriptions RDP security groups"
    foreach ($line in $emptydescrrdp) {
        $descrnamerdp = $line `
            -replace $config.adgroupprefixrdp, ''
        Set-ADGroup `
            -Identity "$line" `
            -Description "Local RDP group to server $descrnamerdp" `
            -GroupScope "Universal"
        Write-Verbose "[$(Get-Date)] Enforcing description for group $line"
    }

}