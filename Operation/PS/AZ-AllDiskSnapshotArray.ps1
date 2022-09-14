#Requires -Version 3
#Az.Accounts
#Az.Compute
#Az.Storage (1.1.0 or greater)
#Az.Resources (1.2.0 or greater)


<#
    .SYNOPSIS
        This runbook create snapshots for all disk (OSDisk and DataDisk) for 1 or more VM's
    .DESCRIPTION
        If more than 1 vm is listed, vm's must exist in the same Resource Group
    .PARAMETER VMNames
        Specifies the VM Name or Names. 
    .PARAMETER VMRG
        Specifies the resouce group which contains the vm's.
    .INPUTS
        WEBHOOKDATA Is used when the runbook is invoked by a webhook
    .OUTPUTS
        System.String. RemoveOlderfiles.ps1 returns a string with the log for the operation.
        System.String. $date + '-' + $TaskName +'.log'
    .EXAMPLE
        PS> AZ-SnapshotDiskArray.ps1 -vmnames 'vm01' -VMRG 'resourcegroup01'
    .NOTES
      Version:        1.0
      Author:         Gonzalo Escajadillo
      Team:           IBM Cloud
      Creation Date:  14/04/2021
      Purpose/Change: Automation Iniatives
      Script Repository: https://github.ibm.com/ibmcloudperu/azurepublic         
#>


# Returns strings with status messages
#[OutputType([String])]

param (

    [Parameter(Mandatory=$false)] [Array]  $VMNames = @('lnxgeewebsite103','lnxgeewebsite104'), # Ingrese una o más VM's
    [Parameter(Mandatory=$false)] [String] $SubscriptionId = 'dd2dbd02-2eb0-46fb-8bdd-1f7d000b1b7e',
    [Parameter(Mandatory=$false)] [String] $VMResourceGroup = 'rsgrwebsite001',
    [Parameter(Mandatory=$false)] [String] $SnapshotResourceGroupName ='arsgrsnapshots',    
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountName = 'staccinfgee01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountRG = 'arsgrinfp01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountContainer = 'logs-snapshotarray',   
    [Parameter(Mandatory=$false)] [String] $TaskName = 'azdss_',
    [Parameter(Mandatory=$false)] [object] $WebhookData
)

# $DebugPreference='Continue'

# Select-AzSubscription -SubscriptionId $SubscriptionId


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


#-----------------------------------------------------------[Authentication]------------------------------------------------------------


$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.

$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint




#-----------------------------------------------------------[Functions]------------------------------------------------------------

function New-AZSnapshotArray {
param(
    $SnapshotResourceGroupName,
    $vm,
    $VMResourceGroup
)
    # Start OSDisk Snapshot
    $OSSnapshotname = $TaskName + $vm.Name+'_OSDisk_'+$date
    $OSSnapshot = New-AzSnapshotConfig -SourceUri  $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy
    New-AzSnapshot  -Snapshot $ossnapshot -SnapshotName $OSSnapshotname  -ResourceGroupName $SnapshotresourceGroupName | Out-File -FilePath $FullLogPath -Append 

    # Get all disk luns
    $luns = $vm.StorageProfile.DataDisks.lun
    # Makes a table with snapshot information
    $lunsforsnapshots = $vm.StorageProfile.DataDisks | Select-Object Lun, Name, DiskSizeGB, @{N='Id'; E={$_.ManagedDisk.Id}} #| Where-Object { $luns -contains $_.Lun }

    # Genera el snapshot para cada lun obtenida en $lunsforsnapshots
    foreach ($lun in $lunsforsnapshots){
        $snapshotname = $TaskName + $vm.Name+'_DataDisk_'+$lun.Lun+'_'+$date
        $snapshot =  New-AzSnapshotConfig -SourceUri $lun.id -Location $vm.Location -CreateOption copy
        New-AzSnapshot  -Snapshot $snapshot -SnapshotName $snapshotname  -ResourceGroupName $SnapshotResourceGroupName | Out-File -FilePath $FullLogPath -Append 
    }
}




#-----------------------------------------------------------[Execution]-------------------------------------------------------------



#### Webhook #####

if ($WebhookData -ne $null) {
    Write-output " ### insde webhoodata ####"
    write-output $webhookdata 

    # Get the info needed to identify the VM (depends on the payload schema)
    $schemaId = $WebhookBody.schemaId
    Write-output  " SchemaId: $schemaId"
    
    # Check header for message to validate request
    if ($WebhookData.RequestHeader.message -eq 'StartedbyServicePortal')
    {
        Write-Output "Header has required information"
        $status = "Activated"
        Write-output " Status: $($status)"
    }
    else
    {
        Write-Output "Header missing required information";
        exit;
    } 

		# Collect properties of WebhookData
		$WebhookName 	= 	$WebhookData.WebhookName
		$WebhookHeaders = 	$WebhookData.RequestHeader
		$WebhookBody 	= 	$WebhookData.RequestBody

        # Print webhook variables:
        Write-output "WebhookName: $($WebhookName)"
        Write-output "WebhookHeaders: $($WebhookHeaders)"
        Write-output "WebhookBody: $($WebhookBody)"
        Write-output "Wwbhookdata.RequestBody: $($WebhookData.RequestBody)"

		# Collect individual headers. VMList converted from JSON.
        $WebhookParameters = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
        		
		Write-Output "Runbook started from webhook $WebhookName ."
        Write-output "$($WebhookParameters)"
        Write-output "Parameter VMName from webhookdata: $($WebhookParameters.VMNames)"
        Write-output "Parameter VMResourceGroup from webhookdata: $($WebhookParameters.VMResourceGroup)"

        $($WebhookParameters.VMNames)
        $($WebhookParameters.VMResourceGroup)

        # Start the log file
        $logmessage = "$($date) - [INFO] - Inicio por Webhook - $($logfile)"  ;
        $logmessage | out-file -FilePath $FullLogPath -Force  ;
        $logmessage = '' ;                
        Write-output "Subscription ID: $($SubId)"
        #Select-AzSubscription -SubscriptionId $SubscriptionId
        #$subscription = get-AzSubscription -SubscriptionId $SubId | Select-AzSubscription
        foreach ($VMName in $($WebhookParameters.VMNames)){
            $vm = Get-AzVM -Name $VMName -ResourceGroupName $($WebhookParameters.VMResourceGroup) # -Status | Where-Object {$_.PowerState -like "VM Running"}
            New-AZSnapshotArray -vm $vm -VMResourceGroup $vm.ResourceGroup -snapshotresourcegroup $SnapshotResourceGroupName
        }
}

else {
    Write-output "###Iniciado a demanda por runbook#####"

    # Start the log file
    $logmessage = "$($date) - [INFO] - Inicio a demanda - $($logfile)"  ;
    $logmessage | out-file -FilePath $FullLogPath -Force  ;
    $logmessage = '' ;

    if ($SubscriptionId){
        #Select-AzSubscription -SubscriptionId $SubscriptionId
        $subscription = get-AzSubscription -SubscriptionId $SubscriptionId | Select-AzSubscription
        foreach ($VMName in $VMNames){
            $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroup # -Status | Where-Object {$_.PowerState -like "VM Running"}
            New-AZSnapshotArray -vm $vm -VMResourceGroup $vm.ResourceGroup -snapshotresourcegroup $SnapshotResourceGroupName
        }
    }

    else {
        # Run on all supported subscriptions
        $subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled') -and ($_.Name -notin $SubscriptionsUnmanaged)} | select Name, Id, State
        write-output = ($subscriptions).Count

        foreach ($subscription in $subscriptions) {
            if ($subscription.State -ne "Disabled") {
                Select-AzSubscription -SubscriptionId $subscription.Id

                foreach ($VMName in $VMNames){
                    $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroup # -Status | Where-Object {$_.PowerState -like "VM Running"}
                    New-AZSnapshotArray -vm $vm -VMResourceGroup $vm.ResourceGroup -snapshotresourcegroup $SnapshotResourceGroupName
                }
            }
        }
    }
}




#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullLogPath  -Blob $LogFile -Force -Verbose

