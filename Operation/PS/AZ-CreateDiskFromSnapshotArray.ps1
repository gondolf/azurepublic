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
    .PARAMETER StorageType
        Provide the storage type for Managed Disk.
         PremiumLRS:Premium_LRS
         StandardLRS:Standard_LRS
         StandardSSDLRS:StandardSSD_LRS
         UltraSSDLRS:UltraSSD_LRS
    .INPUTS
        WEBHOOKDATA 
    .OUTPUTS
        System.String. RemoveOlderfiles.ps1 returns a string with the log for the operation.
        System.String. $date + '-' + $TaskName +'.log'
    .EXAMPLE
        PS> RemoveOlderfiles.ps1 -share ('share02')
        20210209-220853-RemoveOlderFiles.log
#>


# Returns strings with status messages
#[OutputType([String])]
[CmdletBinding()]
param (
   
        [Parameter(Mandatory=$false)] [String]  $SubscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        [Parameter(Mandatory=$false)] [String]  $SnapshotresourceGroupName ='xxxxxxxxxxxxxx',
        [Parameter(Mandatory=$false)] [String]  $DiskResourceGroupName ='xxxxxxxxxxxxxxxxxx',
        [Parameter(Mandatory=$false)] [String]  $ComputerName = "xxxxxxxxxxx",        
        [Parameter(Mandatory=$false)] [String]  $LogStorageAccountName = 'xxxxxxxxxxxxx',
        [Parameter(Mandatory=$false)] [String]  $LogStorageAccountRG = 'xxxxxxxxxxxxx',
        [Parameter(Mandatory=$false)] [String]  $LogStorageAccountContainer = 'logs-diskarray',  
        [Parameter(Mandatory=$false)] [String]  $Snapshotdate = '20210318-225125',
        [Parameter(Mandatory=$false)] [String]  $storageType = 'Standard_LRS', 
        [Parameter(Mandatory=$false)] [String]  $location = 'eastus',
        [Parameter(Mandatory=$false)] [String]  $TaskName = 'diskfromsnapshot_'

    )



#----------------------------------------------------------[Declarations]-----------------------------------------------------------


$TimeStamp = (Get-Date)
$DateTime  = ([DateTime]$timestamp).ToUniversalTime()
$PeruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, 'SA Pacific Standard Time')
$date = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$dateColumn = (Get-Date $PeruTime -DisplayHint Time).DateTime.ToString()
$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;
$LogFile = $date  +'-'+ $TaskName + $ComputerName + '.log';
$FullLogPath = Join-Path -Path $LogPath -ChildPath $LogFile;
$SnapshotName = "*$($computername)*"

#Set the context to the subscription Id where Managed Disk will be created
#Select-AzSubscription -SubscriptionId $SubscriptionId



<#
#-----------------------------------------------------------[Authentication]------------------------------------------------------------


$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.

$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
#>




#-----------------------------------------------[ Execution ]--------------------------------------------------


$snapshots = Get-AzSnapshot -ResourceGroupName $SnapshotresourceGroupName -SnapshotName $snapshotName | Where-Object {($_.Name).Split('_')[-1] -contains $snapshotdate}
Write-Output "#####Snapshots####"
$snapshots | select Name | Write-Output



foreach ($snapshot in $snapshots){
    if ($snapshot.ostype -like $null) {    
        $diskName = $ComputerName + '_DataDisk_'+$snapshot.Name.Split('_')[-2]
        Write-Output "####DiskName####"
        Write-Output $diskName
    }
    else {
        $diskName = $ComputerName + '_OSDisk_'+'01'
        Write-Output $diskName
    }
    $diskConfig = New-AzDiskConfig -SkuName $storageType -Location $location -CreateOption Copy -SourceResourceId $snapshot.Id
    New-AzDisk -Disk $diskConfig -ResourceGroupName $DiskresourceGroupName -DiskName $diskName | Out-File -FilePath $FullLogPath -Append  
}


#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullLogPath  -Blob $LogFile -Force -Verbose

