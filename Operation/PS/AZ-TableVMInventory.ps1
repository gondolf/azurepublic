#Requires -Version 3
#Az.Accounts
#Az.Compute
#Az.Storage (1.1.0 or greater)
#Az.Resources (1.2.0 or greater)
#Az.Table

<#
    .SYNOPSIS
        This runbook will create vm a complete vm inventory.
    .DESCRIPTION
        This process run over all subscriptions which has permissions and also you can exclude any specified subscription.
        This process will safe the inventory in a cosmodb table.
    .PARAMETER SubscriptionId
        Computer name list for the snapshots
    .PARAMETER Extension
        Specifies the extension. "Txt" is the default.
    .INPUTS
        None. You cannot pipe objects to create snapshots ... yet ...
    .OUTPUTS
        System.String. New-AZAllDiskSnapshotArray returns a string with the log for the operation.
        System.String. $date + '_' + $TaskName +'.log'
        System.String. New-AZAllDiskSnapshotArray create azure snapshot for all vm disks.
        System.String. $TaskName + $vm.Name+'_OSDisk_'+$lun.Lun+'_'+$date
        System.String. $TaskName + $vm.Name+'_DataDisk_'+$lun.Lun+'_'+$date
    .EXAMPLE
        PS> New-AZSnapshotFullVM -Computernames ('CROSRVQAS','CROSAPROUTER')
        20201002-233439_azdss_.log
#>


[CmdletBinding()]
param (

#    [Parameter(Mandatory=$false)] 
#    [String]  $SubscriptionId = 'ce59c9c0-e8d7-4774-9bfb-13ca0e98cbee',

#    [Parameter(Mandatory=$false)] 
#    [String]  $CredentialAssetName = "UsrAzureOperator",

#    [Parameter(Mandatory=$false)] 
#    [String]  $StorageAccountName = "blobeu2ibmcp01",    

    [Parameter(Mandatory=$false)] 
    [String]  $CustomerName = "Dinet",    
    
    [Parameter(Mandatory=$false)] 
    [String]  $OutContainer = "runbooksondemand",

    [Parameter(Mandatory=$false)] 
    [String]  $TaskName = "-VMs-Inventory"
)
# $VerbosePreference='Continue'
# $errorActionPreference = "stop"
$DebugPreference='Continue'

#----------------------------------------------------------[Declarations]-----------------------------------------------------------

$date = (Get-Date -UFormat "%Y-%m-%d-%H%M%S").ToString()
$dateColumn = (Get-Date -UFormat "%Y/%m/%d").ToString()
$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;
$LogName = $date + $TaskName + '.log';
$Filename = $date + $TaskName + '.csv';
$FullLogName = Join-Path -Path $LogPath -ChildPath $LogName;
$FullFileName = Join-Path -Path $FilePath -ChildPath $FileName;
$StorageAccountKey = "lm7HXP2xnpDwZL8qqbfcHzHAgXIgmr6blIegcoepatCrw9TSjss4AAO2YfpsPRUN2ZarVEChSqD5qPalJPUCJQ==";
[System.Collections.ArrayList]$Result = @()

##TABLE## - Variables for table
$dateTime = (Get-Date -UFormat "%Y%m").ToString()
[String]  $tableName = 'azvminventory'
[String]  $partitionKey = $dateTime 
[String]  $TableStorageAccountName = 'staccinfeu1p01'
$sasToken = '?sv=2019-12-12&ss=t&srt=sco&sp=rwdlacu&se=2022-12-01T03:46:48Z&st=2020-11-03T19:46:48Z&spr=https&sig=zM%2BceuTbXlJj%2B3EJMISmRo3nY%2FgAHiYLAFh%2B6c%2Bbqag%3D'

##TABLE## - Connect to Azure Table Storage
$storageCtx = New-AzStorageContext -StorageAccountName $TableStorageAccountName -SasToken $sasToken
$table = (Get-AzStorageTable -Name $tableName -Context $storageCtx).CloudTable

# Listado de subscripciones no administrados
$SubscriptionsUnmanaged = @(
    'SUB-DEV-01',
    'SUB-QAS-01'
)


#-----------------------------------------------------------[Authentication]------------------------------------------------------------


$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.

$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
#$AzureContext = Select-AzSubscription -SubscriptionId $conn.subscriptionId; $AzureContext    ## or select a specific subscription
#>

# Run on all supported subscriptions
$subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled') -and ($_.Name -notin $SubscriptionsUnmanaged)} | select Name, Id, State
write-output = ($subscriptions).Count



#-----------------------------------------------------------[Functions]------------------------------------------------------------
 
function Get-VMInfo {
param (
    $CustomerName,
    $dateColumn,
    $vm,
    $DiskType,
    $OSDisk,
    $DataDisks,
    $CreationDate,
    [array]$VMSizes
)

    # Calculate Total Disk Size
    $TotalDiskSize = 0
    $DataDiskSize = 0
    $DataDisks | foreach {$DataDiskSize += $_.DiskSizeGB}
    $TotalDataDiskSize = $DataDiskSize
    $TotalDiskSize = $OSDisk.DiskSizeGB + $DataDiskSize
    
    # Check if size exists
    $VMSize = $VMSizes| Where-Object {$_.Name -eq $vm.hardwareprofile.vmsize}

    # Check for PPG on VM
    if ((Get-AzProximityPlacementGroup -ResourceId $vm.Id ).Id) {$ppg = 'true'} else {$ppg = 'false'}
    
    # Get the NIC details to extract private IP and  subnet
    $nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id | select Name, Ipconfigurations, DnsSettings, EnableIPForwarding ,EnableAcceleratedNetworking
    
    # Get Public IP Address
    if ($nic.IpConfigurations.PublicIpAddress.Id) { 
        $pip = Get-AzPublicIpAddress -Name  $nic.IpConfigurations.PublicIpAddress.Id.Split('/')[-1] -ResourceGroupName $nic.IpConfigurations.PublicIpAddress.Id.Split('/')[4]  | select PublicIpAllocationMethod, IpAddress
    }

    # Build OS string
    if ($vm.StorageProfile.ImageReference.Publisher) {
        $OperatingSystem = ($vm.StorageProfile.ImageReference.Publisher +' '+ $vm.StorageProfile.ImageReference.Offer  + ' ' + $vm.StorageProfile.ImageReference.ExactVersion)
    }
    else { $OperatingSystem = "N/A" }


#    if (!$($vm.Tags.ContainsKey('operation'))) {$vm.Tags['operation'] = 'null'}

    # Build the vminfo object with custom columns
    $vmInfo = [pscustomobject]@{
        'Date' = $dateColumn.ToString()
        #'AccountId' = $subscription.Id
        'AccountName' = $CustomerName
        'Subscription' = $subscription.name
        'PowerState' = $vm.powerstate
        'VMName' = $vm.Name        
        'PrivateIP' = $nic.IpConfigurations.PrivateIpAddress
        'PrivateIPAllocationMethod' = $nic.IpConfigurations.PrivateIpAllocationMethod
        'PublicIP' = if ($pip.IpAddress) {$pip.IpAddress} else {"null"}
        'PublicIPAllocationMethod' = if ($pip.PublicIpAllocationMethod) {$pip.PublicIpAllocationMethod } else {"null"}
        'IPForwarding' = $nic.EnableIPForwarding
        'AcceleratedNetworking' = $nic.EnableAcceleratedNetworking
        'SubNet' = $nic.IpConfigurations.subnet.id.Split("/")[-1]
        'Operation' = if ($vm.Tags['operation']) {$vm.Tags['operation']} else {"null"}
        'MCMS' = if ($vm.Tags['ibm_mcms_managed']) {$vm.Tags['ibm_mcms_managed']} else {"null"}
#        'DNSServer' = $nic.DnsSettings.AppliedDnsServers
#        'Domain' = $nic.DnsSettings.InternalDomainNameSuffix
        'Location' = $vm.Location
        'OperatingSystem' = $OperatingSystem
        'OSDiskSize' = $OSDisk.DiskSizeGB
        'DataDiskSize' = $TotalDataDiskSize
        'TotalDiskSize' = $TotalDiskSize
        'RAM' = if ( $vmsize.MemoryInMB ) {$vmsize.MemoryInMB/1024} else {"null"}   
        'Processor' = if ( $vmsize.NumberOfCores ) {$vmsize.NumberOfCores} else {"null"}
        'VMSize' = if ($VMSize) {$VMSize.Name} else {"null"}        
        'PPG' = if ( $ppg ) {$ppg.ToString()} else {"null"}
        'NIC_Quantity' = if ($vm.NetworkProfile.NetworkInterfaces.Count -gt 0) { $vm.NetworkProfile.NetworkInterfaces.Count} else {"null"}
        'DataDisk_Quantity' = if ($DataDisks.Count -gt 0) { $DataDisks.Count.ToString() } else { "null" };
        'DeviceType' = $vm.Type.ToString() ;
        'CreateDate' = $CreationDate.ToString() ;
        'OperatingSystemType' = $vm.StorageProfile.OsDisk.OsType.ToString() ;
    }

    # Convert pscustomobject array in hashtable
    $hashtable = @{}
    foreach( $property in $vmInfo.psobject.properties.name )
    {
        $hashtable[$property] = $vmInfo.$property
    }

    Write-Output $hashtable
    #return $vmInfo | Export-Csv -notypeinformation -Path $FileName -Encoding UTF8 -Append -Force;  

    Add-AzTableRow -property $hashtable  -UpdateExisting  -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring())    #| Out-Null  

    # $Result += $vmInfo | Export-Csv -notypeinformation -Path $FullFileName -Encoding UTF8 -Append ;  
}


#-----------------------------------------------------------[Execution]-------------------------------------------------------------

$VMSizes = Get-AzVMSize -Location eastus2

foreach ($subscription in $subscriptions) {
    Select-AzSubscription -SubscriptionId $subscription.Id | out-null
    # Get VM Size DetailInfo
    $vms = Get-AzVM -Status # | Where-Object { $null -ne $_.NetworkProfile.NetworkInterfaces}  -and $_.Tags.Keys -like 'opera*'}

    foreach ($vm in $vms) { 
        # Check if VM has a managed / unmanaged disk and if belogs to an availaiblity set
        if ($vm.StorageProfile.OsDisk.ManagedDisk) {
            $DiskType = "Managed"
            $OSDisk = Get-AzDisk -Name $vm.StorageProfile.OsDisk.Name -ResourceGroupName $vm.ResourceGroupName # | select DiskSizeGB, TimeCreated
            $DataDisks = $vm.StorageProfile.DataDisks.name | foreach {Get-AzDisk -Name $_ -ResourceGroupName $vm.ResourceGroupName  | select Name, DiskSizeGB}
            $VMCreationTimeStamp = $OSDisk.TimeCreated.Datetime
            $CreationDate = Get-Date -Date $VMCreationTimeStamp -UFormat "%m/%d/%Y %H:%M:%S"
        }
        else {
            $DiskType = "Unmanaged"
            $VMCreationTimeStamp = (Get-AzStorageBlob `
            -Context (Get-AzStorageAccount -Name $vm.StorageProfile.OsDisk.vhd.Uri.Substring(8).Split(".")[0] `
            -ResourceGroupName $vm.ResourceGroupName).Context -Container $vm.StorageProfile.OsDisk.vhd.Uri.Substring(8).Split("/")[1] `
            -Blob $vm.StorageProfile.OsDisk.vhd.Uri.Substring(8).Split("/")[2]).ICloudBlob.Properties.Created.Datetime
            $CreationDate = Get-Date -Date $VMCreationTimeStamp -UFormat "%m/%d/%Y %H:%M:%S"
        }

        # Check if vm belongs to an availability set
        if (($vm.AvailabilitySetReference.id)){
            $ASName = ($vm.AvailabilitySetReference.id).Split('/')[8]
        }
        else{
            $ASName = "None"
        } 

        # Run and take parameters for function
            Get-VMInfo -DiskType $DiskType -CreationDate $CreationDate -VMSizes $VMSizes -vm $vm -OSDisk $OSDisk -DataDisks $DataDisks -dateColumn $dateColumn -CustomerName $CustomerName
    }
     $Result | Export-Csv -notypeinformation -Path $FullFileName -Encoding UTF8 -Append ;  
    # Start-Sleep -Seconds 10
}


<#

# Generate token for invoke http request
$AccessToken = ((Get-AzContext).TokenCache.ReadItems()  | Sort-Object -Property ExpiresOn -Descending)[0]
$headers = @{ "Authorization" = "Bearer " + $AccessToken.AccessToken }


$url = "https://management.azure.com/Subscriptions/$($subscription.Id)/resourceGroups/$($vmx.resourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($vmx.Name)?$expand=instanceView&api-version=2020-06-01"
#$url = "https://management.azure.com/Subscriptions/$($subscription.Id)/resourceGroups/$($vm.resourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($vm.Name)?api-version=2020-06-01"
$vaultsMethod = Invoke-RestMethod -Uri $url -Headers $headers
$vaultsMethod | ConvertTo-Json
#>

