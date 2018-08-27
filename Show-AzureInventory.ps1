<#
.SYNOPSIS
Shows all current Azure subscriptions

.DESCRIPTION
This function extracts inventory from all azure subscriptions.

.EXAMPLE
Show-AzureInventory -ShowSubscriptions -Verbose
Show-AzureInventory -ShowAllVMs -verbose
Show-AzureInventory -Subscription "name" -Verbose

.NOTES
Function name:          Show-AzureInventory
Author:                 Dennis Kool
DateCreated:            28-06-2018
DateModified:           28-06-2018

.NOTES
28-06-2018:             Initial release
16-07-2018:             Show VM's that needs customer initiated maintenance
30-07-2018:             Used Get-AzureRMResource to extract information
#>


function Show-AzureInventory {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        $Subscription,
        [switch] $ShowSubscriptions,
        [switch] $ShowAllVMs
    )

    #connect to azure
    Write-Verbose "[$(Get-Date)] Connecting to Azure"
    Connect-AzureRmAccount `
        -Credential $hash.AzureReadonly >$null

    #get subscriptions
    if ($ShowSubscriptions) {
        Write-Verbose "[$(Get-Date)] Gathering all subscriptions"
        $azuresubs = Get-AzureRmSubscription |Select-Object `
            -ExpandProperty Name

        foreach ($sub in $azuresubs) {
            Write-Verbose "$sub"
        }
    }

    if ($ShowAllVMs) {
        Write-Verbose "[$(Get-Date)] Gathering VM's in all subscriptions"
        $list = Get-AzureRmSubscription |Select-Object `
            -ExpandProperty Name

        $hostnames = foreach ($sub in $list) {
            Select-AzureRmSubscription `
                -Subscription $sub > $null; Get-AzureRmVM
        }

        $array = foreach ($server in $hostnames) {
            New-object -typename psobject -property @{
                HostName          = $server.Name
                OS                = $server.storageprofile.osdisk.ostype
                ResourceGroupName = $server.ResourceGroupName
                Location          = $server.Location
            }
        }

        #convert array to string. use $array.gettype() to check
        $Inv = $array | Out-String
        Write-Verbose $Inv
    }

    if ($Subscription) {
        Write-Verbose "[$(Get-Date)] Extracting information from subscription $subscription"
        Select-AzureRmSubscription `
            -Subscription $Subscription > $null

        $SubscriptionDetails = Get-AzureRmSubscription `
            -SubscriptionName $Subscription

        $VirtualMachines = Get-AzureRmResource `
            -ResourceType Microsoft.Compute/virtualMachines | Select-Object `
            -ExpandProperty Name

        $VirtualNetworks = Get-AzureRmResource `
            -ResourceType Microsoft.Network/virtualNetworks | Select-Object `
            -ExpandProperty Name

        $DiskName = Get-AzureRmResource `
            -ResourceType Microsoft.Compute/disks | Select-Object `
            -ExpandProperty Name

        $NSG = Get-AzureRmResource `
            -ResourceType Microsoft.Network/networkSecurityGroups | Select-Object `
            -ExpandProperty Name

        $PublicIPs = Get-AzureRmResource `
            -ResourceType Microsoft.Network/publicIPAddresses | Select-Object `
            -ExpandProperty Name

        $lb = Get-AzureRmResource `
            -ResourceType Microsoft.Network/loadBalancers | Select-Object `
            -ExpandProperty Name

        $NetworkInterfaces = Get-AzureRmResource `
            -ResourceType Microsoft.Network/networkInterfaces | Select-Object `
            -ExpandProperty Name

        $keyvaults = Get-AzureRmResource `
            -ResourceType Microsoft.KeyVault/vaults | Select-Object `
            -ExpandProperty Name

        $Recoveryvaults = Get-AzureRmResource `
            -ResourceType Microsoft.RecoveryServices/vaults | Select-Object `
            -ExpandProperty Name

        $storageaccounts = Get-AzureRmResource `
            -ResourceType Microsoft.Storage/storageAccounts | Select-Object `
            -ExpandProperty Name

        $localnetworkgw = Get-AzureRmResource `
            -ResourceType Microsoft.Network/localNetworkGateways | Select-Object `
            -ExpandProperty Name

        $virtualnetworkgw = Get-AzureRmResource `
            -ResourceType Microsoft.Network/virtualNetworkGateways | Select-Object `
            -ExpandProperty Name

        $routetbl = Get-AzureRmResource `
            -ResourceType Microsoft.Network/routeTables | Select-Object `
            -ExpandProperty Name

        $applicationgw = Get-AzureRmResource `
            -ResourceType Microsoft.Network/applicationGateways | Select-Object `
            -ExpandProperty Name

        $dnsz = Get-AzureRmResource `
            -ResourceType Microsoft.Network/dnszones | Select-Object `
            -ExpandProperty Name

        $availset = Get-AzureRmResource `
            -ResourceType Microsoft.Compute/availabilitySets | Select-Object `
            -ExpandProperty Name

        $accounts = Get-AzureRmResource `
            -ResourceType Microsoft.DataLakeStore/accounts | Select-Object `
            -ExpandProperty Name

        $mngcluster = Get-AzureRmResource `
            -ResourceType Microsoft.ContainerService/managedClusters | Select-Object `
            -ExpandProperty Name

        $images = Get-AzureRmResource `
            -ResourceType Microsoft.Compute/images | Select-Object `
            -ExpandProperty Name

        $aaccounts = Get-AzureRmResource `
            -ResourceType Microsoft.Automation/automationAccounts | Select-Object `
            -ExpandProperty Name

        $runb = Get-AzureRmResource `
            -ResourceType Microsoft.Automation/automationAccounts/runbooks | Select-Object `
            -ExpandProperty Name

        $site = Get-AzureRmResource `
            -ResourceType Microsoft.Web/sites | Select-Object `
            -ExpandProperty Name

        $sitehostnames = foreach ($s in $site) {
            Get-AzureRmWebApp `
                -Name $s | Select-Object `
                -ExpandProperty Hostnames
        }

        $siteoutboundIP = Get-AzureRmWebApp | Select-Object `
            -ExpandProperty OutboundIpAddresses
        
        $siteoutboundIPs = $siteoutboundIP `
            -split ','
        
        $siterepository = Get-AzureRmWebApp | Select-Object `
            -ExpandProperty RepositorySiteName
        
        $sfarm = Get-AzureRmResource `
            -ResourceType Microsoft.Web/serverFarms | Select-Object `
            -ExpandProperty Name

        $nconnection = Get-AzureRmResource `
            -ResourceType Microsoft.Network/connections | Select-Object `
            -ExpandProperty Name

        $MaintenanceNeeded = Get-AzureRmVM `
            -Status | Where-Object {$_.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed} | Select-Object `
            -ExpandProperty Name

        $SubnetAddressPrefix = (Get-AzureRmVirtualNetwork).Subnets.AddressPrefix
        $SubnetAddressName = (Get-AzureRmVirtualNetwork).Subnets.Name

        Write-Verbose "[$(Get-Date)] Subscription name : $($SubscriptionDetails.Name | Out-String -stream)"
        Write-Verbose "[$(Get-Date)] Subscription ID :  $($SubscriptionDetails.SubscriptionId | Out-String -stream)"
        Write-Verbose "[$(Get-Date)] Tenant ID: $($SubscriptionDetails.TenantId | Out-String -Stream)"
        Write-Verbose "[$(Get-Date)] Environment: $($SubscriptionDetails.ExtendedProperties.Environment | Out-String -Stream)"
        Write-Verbose "[$(Get-Date)] Current SubscriptionState : $($SubscriptionDetails.State | Out-String -Stream)"

        foreach ($vm in $VirtualMachines) {
            Write-Verbose "[$(Get-Date)] Hostname detected : $vm"
        }
        
        foreach ($disk in $diskname) {
            Write-Verbose "[$(Get-Date)] Disk detected : $disk"
        }

        foreach ($wsite in $site) {
            Write-Verbose "[$(Get-Date)] Website detected : $wsite"
        }

        foreach ($hname in $sitehostnames) {
            Write-Verbose "[$(Get-Date)] Website hostname detected : $hname"
        }

        foreach ($soutboundips in $siteoutboundIPs) {
            Write-Verbose "[$(Get-Date)] Website outbound IPs detected : $soutboundips"
        }

        foreach ($srepo in $siterepository) {
            Write-Verbose "[$(Get-Date)] Website site repository detected : $srepo"
        }

        foreach ($farm in $sfarm) {
            Write-Verbose "[$(Get-Date)] ServerFarm detected : $farm"
        }

        foreach ($runbook in $runb) {
            Write-Verbose "[$(Get-Date)] Runbook detected : $runbook"
        }

        foreach ($saccount in $storageaccounts) {
            Write-Verbose "[$(Get-Date)] Storage account detected : $saccount"
        }

        foreach ($aacount in $aaccounts) {
            Write-Verbose "[$(Get-Date)] Automation account detected : $aacount"
        }

        foreach ($account in $accounts) {
            Write-Verbose "[$(Get-Date)] Account detected : $account"
        }

        foreach ($aset in $availset) {
            Write-Verbose "[$(Get-Date)] Availability set detected: $aset"
        }

        foreach ($mclu in $mngcluster) {
            Write-Verbose "[$(Get-Date)] Managed cluster detected : $mclu"
        }

        foreach ($pubip in $PublicIPs) {
            Write-Verbose "[$(Get-Date)] Public IP detected : $pubip"
        }

        foreach ($conn in $nconnection) {
            Write-Verbose "[$(Get-Date)] Connection detected : $conn"
        }

        foreach ($rtable in $routetbl) {
            Write-Verbose "[$(Get-Date)] Route table detected : $rtable"
        }

        foreach ($lbr in $lb ) {
            Write-Verbose "[$(Get-Date)] Loadbalancer detected : $lbr"
        }

        foreach ($networkname in $VirtualNetworks) {
            Write-Verbose "[$(Get-Date)] Virtual Network detected : $networkname"
        }

        foreach ($appgw in $applicationgw) {
            Write-Verbose "[$(Get-Date)] Application gateway detected : $appgw"
        }

        foreach ($vgateway in $virtualnetworkgw) {
            Write-Verbose "[$(Get-Date)] Virtual network gateway detected : $vgateway"
        }

        foreach ($lgateway in $localnetworkgw) {
            Write-Verbose "[$(Get-Date)] Local network gateway detected : $lgateway"
        }

        foreach ($zone in $dnsz) {
            Write-Verbose "[$(Get-Date)] DNS zone detected : $zone"
        }

        foreach ($subnetname in $SubnetAddressName) {
            Write-Verbose "[$(Get-Date)] Subnet detected : $($subnetname | Out-String -stream)"
        }

        foreach ($prefix in $SubnetAddressPrefix) {
            Write-Verbose "[$(Get-Date)] Subnet prefix detected : $($prefix | Out-String -stream)"
        }

        foreach ($group in $NSG) {
            Write-Verbose "[$(Get-Date)] NSG detected : $group"
        }

        foreach ($interface in $NetworkInterfaces) {
            Write-Verbose "[$(Get-Date)] Network interface detected : $interface"
        }

        foreach ($vault in $keyvaults) {
            Write-Verbose "[$(Get-Date)] Keyvault detected : $vault"
        }

        foreach ($rvault in $Recoveryvaults) {
            Write-Verbose "[$(Get-Date)] Recovery Services vault detected : $rvault"
        }

        foreach ($image in $images) {
            Write-Verbose "[$(Get-Date)] Image detected : $image"
        }

        foreach ($VM in $MaintenanceNeeded) {
            Write-Verbose "[$(Get-Date)] Maintenance needed for : $VM"
        }

    }

}