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
01-05-2018:             Changed name property to Name
07-05-2018:             Added NL-SG RDP groups
11-05-2018:             Cleanup groups with no existing AD object
11-05-2018:             Enforce empty descriptions on objects
22-05-2018:             Changed groupscope to universal
18-06-2018:             Added verbose parameter
06-07-2018:             Added timestamp to verbose logging
#>


function Start-IntegrityCheckADGroups {

    [CmdletBinding()]
    param()

    #set dynamic variables
    Set-Variable `
        -Name file `
        -Value "D:\Scripts\Start-IntegrityCheckADGroups\Output\ad-creategroups-$((Get-Date).ToString('MM-dd-yyyy')).log"

    $hashadcheck = Import-Clixml -Path "D:\Scripts\Creds\nlsvcintegritych.cred"

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

    #create dynamic exception list
    Write-Verbose "[$(Get-Date)] Creating exception list"
    $domaincontrollers = $config.domaincontrollers

    $Servers = Get-ADComputer -Filter {OperatingSystem -Like "Windows Server*"} -Properties * |select-Object * -expandproperty name
    $failover = $servers | Where-Object {$_.description -like "*failover*"} | Select-Object `
        -ExpandProperty Name

    $exception = $domaincontrollers + $failover

    #create list of servers and security groups
    Write-Verbose  "[$(Get-Date)] Extracting existing LAM groups from active directory"
    $ExistingLamGroups = Get-ADGroup -filter * | Where-Object {
        $_.Name -like $config.ADGroupPrefixLamWildcard} | Select-Object `
        -ExpandProperty Name

    Write-Verbose  "[$(Get-Date)] Extracting existing RDP groups from active directory"
    $ExistingRdpGroups = Get-ADGroup -filter * | Where-Object {
        $_.Name -like $config.ADGroupPrefixRdpWildcard} | Select-Object `
        -ExpandProperty Name

    $ExistingLamGroup = foreach ($line in $ExistingLamGroups) {
        $line -replace $config.ADGroupPrefixLam, ""
    }

    $ExistingRdpGroup = foreach ($lines in $ExistingRdpGroups) {
        $lines -replace $config.ADGroupPrefixRdp, ""
    }

    Write-Verbose "[$(Get-Date)] Extracting server list from active directory"
    $servernames = Get-ADComputer -Filter {OperatingSystem -Like "Windows Server*"} `
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

    #  #enforce descriptions LAM groups
    #  Write-Verbose "[$(Get-Date)] Enforcing description LAM security groups"
    #  foreach ($entry in $ExistingLamGroup) {
    #      Set-ADGroup `
    #          -Identity "$ADGroupPrefixLam$entry" `
    #          -Credential $hash.domainadmin `
    #          -Description "Local Admin group to server $entry" `
    #          -GroupScope "Universal"
    #  }

    #  #enforce descriptions RDP groups
    #  Write-Verbose "[$(Get-Date)] Enforcing description RDP security groups"
    #  foreach ($entry in $ExistingRdpGroup) {
    #      Set-ADGroup `
    #          -Identity "$ADGroupPrefixRdp$entry" `
    #          -Credential $hash.domainadmin `
    #          -Description "Local RDP group to server $entry" `
    #          -GroupScope "Universal"
    #  }

}


