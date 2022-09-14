#Requires -Version 3
#Az.Accounts (2.5 or grater)
#Az.Compute
#Az.Storage (1.1.0 or greater)
#Az.Resources (1.2.0 or greater)
#Az.Network
#AzTable

<#
    .SYNOPSIS
        This runbook will create a complete vm inventory invoked by webhooks from azure monitor.
    .DESCRIPTION
        This process run over all subscriptions which has permissions and also you can exclude any specified subscription.
        This process will safe the inventory in a cosmodb table.
	This script can be invoked through azure monitor to update the database each time a vm is created or deleted.
    .PARAMETER SubscriptionId
        Computer name list for the snapshots
    .PARAMETER CustomerName
        Specifies the Customer Name which will be include as a record in the Azure Table.
    .INPUTS
        WEBHOOKDATA Used if the runbook is invoked by a webhook
    .OUTPUTS
	Azure Tables record
    .EXAMPLE
        PS> AZ-VMInventory.ps1
    .NOTES
      Version:        1.0
      Author:         Gonzalo Escajadillo
      Email:	      gonzalo.adolfo.escajadillo@ibm.com
      Team:           IBM Cloud
      Creation Date:  21/04/2021
      Purpose/Change: Automation Iniatives
      Script Repository: https://github.ibm.com/ibmcloudperu/azurepublic    	
#>


#[CmdletBinding()]
param (

    [Parameter(Mandatory=$false)] [String]  $CustomerName = "Crosland",    
    [Parameter(Mandatory=$false)] [String]  $TaskName = "-VMs-Inventory",
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountName = 'staccinftab01',
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountContainer = 'logs-vmsinventory',    
    [Parameter (Mandatory=$false)] [object] $WebhookData
)
# $VerbosePreference='Continue'
# $errorActionPreference = "stop"
$DebugPreference='Continue'

#----------------------------------------------------------[Declarations]-----------------------------------------------------------

$TimeStamp = (Get-Date)
$DateTime  = ([DateTime]$timestamp).ToUniversalTime()
$PeruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, 'SA Pacific Standard Time')
$date = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$dateColumn = (Get-Date $PeruTime -DisplayHint Time).DateTime.ToString()
$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;
$LogFile = $date  +'-'+ $TaskName + '.log';
$FullLogPath = Join-Path -Path $LogPath -ChildPath $LogFile;


##TABLE## - Variables for table
$dateTime = (Get-Date -UFormat "%Y%m%d").ToString()
[String]  $tableName = 'azvminventory'
[String]  $partitionKey = $dateTime 
[String]  $TableStorageAccountName = 'staccinftab01'
$sasToken = '**************************************************************************************************************************'


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


#-----------------------------------------------------------[Functions]------------------------------------------------------------
 
function Get-VMInfo {
param (
    $Subscription,
    $CustomerName,
    $dateColumn,
    $vm,
    $DiskType,
    $OSDisk,
    #$DataDisks,
    $CreationDate,
    [array]$VMSizes
)

    # New VM Object with status
    $StatusVM = Get-AzVM  -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status
    

    # Calculate Total Disk Size
    if ($vm.StorageProfile.DataDisks.count -gt '0'){
        $TotalDiskSize = 0
        $DataDiskSize = 0
        $TotalDataDiskSize = 0        
        $DataDisks = $vm.StorageProfile.DataDisks | foreach {
            $DataDiskSize += (Get-AzDisk -DiskName $_.name).DiskSizeGB
            }
        $DataDiskQuantity = $vm.StorageProfile.DataDisks.Count
        write-output $DataDiskSize      
    }
    else { 
        $DataDiskQuantity = '0'
        $DataDisks = 0
        $TotalDiskSize = 0        
        $DataDiskSize = 0        
    }
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

    # Get OS from VM Status
    if ($vm.StorageProfile.OsDisk.OsType -like 'Linux'){
        $OperatingSystem = ($StatusVM.OsName + ' ' + $StatusVM.OsVersion)
    }
    else{
        $OperatingSystem = $StatusVM.OsName
    }


#    if (!$($vm.Tags.ContainsKey('operation'))) {$vm.Tags['operation'] = 'null'}
    write-output $subscription.name
    write-output $subscription.id
    write-output $vm.osname
    write-output $vm.osversion
    # Build the vminfo object with custom columns
    $vmInfo = [pscustomobject]@{
        'Date' = $dateColumn.ToString() ;
        'AccountName' = $CustomerName ;
        'Subscription' = $subscription.Name ;
        'SubscriptionId' = $subscription.Id ;
        'PowerState' = if ($StatusVM.Statuses[1].DisplayStatus) {$StatusVM.Statuses[1].DisplayStatus} else {"null"} ;
        'VMName' = $vm.Name ;
        'Hostname' = if ($StatusVM.ComputerName) {$StatusVM.ComputerName} else {"null"} ;
        'ResourceGroup' = if ($vm.ResourceGroupName) {$vm.ResourceGroupName} else {"null"} ;
        'PrivateIP' = $nic.IpConfigurations.PrivateIpAddress ;
        'PrivateIPAllocationMethod' = $nic.IpConfigurations.PrivateIpAllocationMethod ;
        'PublicIP' = if ($pip.IpAddress) {$pip.IpAddress} else {"null"} ;
        'PublicIPAllocationMethod' = if ($pip.PublicIpAllocationMethod) {$pip.PublicIpAllocationMethod } else {"null"} ;
        'IPForwarding' = $nic.EnableIPForwarding ;
        'AcceleratedNetworking' = $nic.EnableAcceleratedNetworking ;
        'SubNet' = $nic.IpConfigurations.subnet.id.Split("/")[-1] ;
        'Operation' = if ($vm.Tags['operation']) {$vm.Tags['operation']} else {"null"} ;
        'MCMS' = if ($vm.Tags['ibm_mcms_managed']) {$vm.Tags['ibm_mcms_managed']} else {"null"} ;
        'Location' = $vm.Location ;
#       'OperatingSystem' = $OperatingSystem
#       'OperatingSystemVersion' = if ($StatusVM.OsVersion) {$StatusVM.OsVersion} else {"null"}    ;
        'OperatingSystem' = if ($OperatingSystem) {$OperatingSystem} else {"null"} ;
        'OperatingSystemType' = $vm.StorageProfile.OsDisk.OsType.ToString() ;  
        'OSDiskSize' = $OSDisk.DiskSizeGB ;
        'DataDiskSize' = $DataDiskSize ;
        'DataDisk_Quantity' = $DataDiskQuantity ;        
        'TotalDiskSize' = $TotalDiskSize ;
        'RAM' = if ( $VMSize.MemoryInMB ) {$VMSize.MemoryInMB/1024} else {"null"} ;
        'Processor' = if ( $VMSize.NumberOfCores ) {$VMSize.NumberOfCores} else {"null"} ;
        'VMSize' = if ($VMSize) {$VMSize.Name} else {"null"} ;
        'PPG' = if ( $ppg ) {$ppg.ToString()} else {"null"} ;
        'NIC_Quantity' = if ($vm.NetworkProfile.NetworkInterfaces.Count -gt 0) { $vm.NetworkProfile.NetworkInterfaces.Count} else {"null"} ;
        'DeviceType' = $vm.Type.ToString() ;
        'CreateDate' = $CreationDate.ToString() ;
    }

    # Convert pscustomobject array in hashtable
    $hashtable = @{}
    foreach( $property in $vmInfo.psobject.properties.name )
    {
        $hashtable[$property] = $vmInfo.$property
    }

    Write-Output $hashtable
    Add-AzTableRow -property $hashtable  -UpdateExisting  -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring())  # 2>&1 | Tee-Object -FilePath $FullLogPath -Append
 
}


#-----------------------------------------------------------[Execution]-------------------------------------------------------------

# Start the log file
$logmessage = "$($date) - [INFO] - Inicio de log - $($logfile)"  ;
$logmessage | out-file -FilePath $FullLogPath -Force  ;
$logmessage = '' ;


if ($WebhookData) {
    # Get the data object from WebhookData
    $WebhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    Write-output $WebhookBody   
    # Get the info needed to identify the VM (depends on the payload schema)
    $schemaId = $WebhookBody.schemaId
    Write-Verbose "schemaId: $schemaId" -Verbose
    if ($schemaId -eq "azureMonitorCommonAlertSchema") {
        # This is the common Metric Alert schema (released March 2019)
        $Essentials = [object] ($WebhookBody.data).essentials
        # Get the first target only as this script doesn't handle multiple
        $alertTargetIdArray = (($Essentials.alertTargetIds)[0]).Split("/")
        $SubId = ($alertTargetIdArray)[2]
        $ResourceGroupName = ($alertTargetIdArray)[4]
        $ResourceType = ($alertTargetIdArray)[6] + "/" + ($alertTargetIdArray)[7]
        $ResourceName = ($alertTargetIdArray)[-1]
        $status = $Essentials.monitorCondition
    }
    elseif ($schemaId -eq "AzureMonitorMetricAlert") {
        # This is the near-real-time Metric Alert schema
        $AlertContext = [object] ($WebhookBody.data).context
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = $AlertContext.resourceName
        $status = ($WebhookBody.data).status
    }
    elseif ($schemaId -eq "Microsoft.Insights/activityLogs") {
        # This is the Activity Log Alert schema
        $AlertContext = [object] (($WebhookBody.data).context).activityLog
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = (($AlertContext.resourceId).Split("/"))[-1]
        $ResourceId = $AlertContext.resourceId
        $status = ($WebhookBody.data).status
        $operationName = ($WebhookBody.data).$operationName
    }
    elseif ($schemaId -eq $null) {
        # This is the original Metric Alert schema
        $AlertContext = [object] $WebhookBody.context
        $SubId = $AlertContext.subscriptionId
        $ResourceGroupName = $AlertContext.resourceGroupName
        $ResourceType = $AlertContext.resourceType
        $ResourceName = $AlertContext.resourceName
        $status = $WebhookBody.status
    }
    else {
        # Schema not supported
        Write-Error "The alert data schema - $schemaId - is not supported."
    }

    # $status = "Fired" # Descomentar para lanzar el runbook manualmente
    Write-Verbose "status: $status" -Verbose
    Write-Output " ResourceName: $($ResourceName)"
    Write-Output  $WebhookBody.operationName
    Write-Output " AlertContext.operationName: $($AlertContext.operationName)"
    Write-Output " ResourceId: $ResourceId"
    Write-Output "resourceGroupName: $($resourceId.Split('/')[4])"      
    Write-Output " ########"
    Write-output " $WebhookBody"
    Write-output " $AlertContext"
    Write-output " $ResourceType"
    Write-Output " ########"

		if (($status -eq "Activated") -or ($status -eq "Fired")) {
            ### Check if deployment was for a virtual machine
            $resource = Get-AzResource -ResourceId $resourceId
            $currentdeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resource.ResourceGroupName | Where-Object {$_.DeploymentName -like $resourceId.Split('/')[-1] }
            if ($currentdeployment.Parameters.Keys.Contains("virtualMachineName")){
                Write-Output "DeploymentName: $($resourceId.Split('/')[-1])"
                Write-Verbose "resourceType: $ResourceType" -Verbose
                Write-Verbose "resourceName: $ResourceName" -Verbose
                Write-Verbose "resourceGroupName: $resource.ResourceGroupName" -Verbose
                Write-Verbose "subscriptionId: $SubId" -Verbose
                
                #### Code starts here ###
                $VMSizes = Get-AzVMSize -Location eastus2

                # Run on all supported subscriptions
                $subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled') -and ($_.Name -notin $SubscriptionsUnmanaged)} | select Name, Id, State
                write-output = "Subscription Quantity: $($subscriptions).Count"

                foreach ($subscription in $subscriptions) {
                    Select-AzSubscription -SubscriptionId $subscription.Id | out-null
                    # Get VM Size DetailInfo
                    $vms = Get-AzVM #-Status  | Where-Object { $null -ne $_.NetworkProfile.NetworkInterfaces}  -and $_.Tags.Keys -like 'opera*'}

                    foreach ($vm in $vms) { 
                        # Check if VM has a managed / unmanaged disk and if belogs to an availaiblity set
                        if ($vm.StorageProfile.OsDisk.ManagedDisk) {
                            $DiskType = "Managed"
                            $OSDisk = Get-AzDisk -Name $vm.StorageProfile.OsDisk.Name -ResourceGroupName $vm.ResourceGroupName # | select DiskSizeGB, TimeCreated
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
                            Get-VMInfo -DiskType $DiskType -CreationDate $CreationDate -VMSizes $VMSizes -vm $vm -OSDisk $OSDisk -dateColumn $dateColumn -CustomerName $CustomerName -Subscription $subscription # 2>&1 | Tee-Object -FilePath $FullLogPath -Append
                    }
                    # $Result | Export-Csv -notypeinformation -Path $FullFileName -Encoding UTF8 -Append ;  
                    # Start-Sleep -Seconds 10
                }
            }
            else {
                Write-Output "DeploymentResources: $($currentdeployment.Parameters.Keys)"
                Write-Output "DeploymentName: $($resourceId.Split('/')[-1])"
                $logmessage = "$($dateColumn) - [WARN] - +  Deployment es diferente a VirtualMachine"
                $logmessage | Out-File -FilePath $FullLogPath -Append

            }
		}
        else {
            # The alert status was not 'Activated' or 'Fired' so no action taken
            Write-Verbose ("No action taken. Alert status: " + $status) -Verbose
            $logmessage = "$($dateColumn) - [WARN] - +  La alerta no se activó"
            $logmessage | Out-File -FilePath $FullLogPath -Append            
        }
}



#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullLogPath  -Blob $LogFile -Force -Verbose


