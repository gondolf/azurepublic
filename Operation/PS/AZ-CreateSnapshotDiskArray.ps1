#Requires -Version 3
#Az.Accounts
#Az.Compute
#Az.Storage (1.1.0 or greater)
#Az.Resources (1.2.0 or greater)


<#
    .SYNOPSIS
        This runbook creates snapshots for all disk (OSDisk and DataDisk) for 1 or more VM's
    .DESCRIPTION
        If more than 1 vm is listed, vm's must exist in the same Resource Group
    .PARAMETER VMNames
        Specifies the VM Name or Names. 
    .PARAMETER VMRG
        Specifies the resouce group which contains the vm's.
    .INPUTS
        WEBHOOKDATA Used if the runbook was invoked by a webhook
    .OUTPUTS
        System.String. RemoveOlderfiles.ps1 returns a string with the log for the operation.
        System.String. $date + '-' + $TaskName +'.log'
    .EXAMPLE
        PS> AZ-CreateSnapshotDiskArray.ps1 -VMName server01 -VMRG ResourceGroup01
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

    [Parameter(Mandatory=$false)] [Array] $VMNames = @('SVFDECROPRO-test','SVWEBINCPRO-test'), # Ingrese una o más VM's
    [Parameter(Mandatory=$false)] [String]  $SubscriptionId = 'dd2dbd02-2eb0-46fb-8bdd-1f7d000b1b7e',
    [Parameter(Mandatory=$false)] [String] $VMRG = 'ARSGRAPPEU1P01',
    [Parameter(Mandatory=$false)] [String]  $SnapshotresourceGroupName ='arsgrsapeu1s01',    
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountName = 'staccinftab01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountContainer = 'logs-snapshotarray',   
    [Parameter(Mandatory=$false)] [String]  $TaskName = 'azdss_'
)

$DebugPreference='Continue'

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




#-----------------------------------------------------------[Execution]-------------------------------------------------------------

# Start the log file
$logmessage = "$($date) - [INFO] - Inicio de log - $($logfile)"  ;
$logmessage | out-file -FilePath $FullLogPath -Force  ;
$logmessage = '' ;

foreach ($VMName in $VMNames){

    $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMRG # -Status | Where-Object {$_.PowerState -like "VM Running"}
     
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
        New-AzSnapshot  -Snapshot $snapshot -SnapshotName $snapshotname  -ResourceGroupName $SnapshotresourceGroupName | Out-File -FilePath $FullLogPath -Append 
    }
}




#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullLogPath  -Blob $LogFile -Force -Verbose

