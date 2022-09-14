# Stora
#Requires -Version 3
#Az.Accounts
#Az.Compute
#Az.Storage (1.1.0 or greater)
#Az.Resources (1.2.0 or greater)
#Az.Table
#Az.RecoveryServices (2.8.0 or greater)

<#
    .SYNOPSIS
        This runbook will run a azure file share backup on demand, scheduled as a runbook job
    .DESCRIPTION
        This process launch a azure backup job for an azure file share backup.
        If the backup job finish successfully, it will execute a powershell function to delete files recursively
        This process will save the operations logs in a storage account file.
    .PARAMETER SubscriptionId
        Specifies the subscription ID. 
    .PARAMETER LogShare
        Specifies the share that will be used to save the operation logs.
    .INPUTS
        INPUT mandatory parameters are: SHARENAME, STORAGEACCOUNTNAME, STORAGEACCOUNTRG and TARGETFOLDERS
    .OUTPUTS
        System.String. RemoveOlderfiles.ps1 returns a string with the log for the operation.
        System.String. $date + '-' + $TaskName +'.log'
    .NOTES
      Version:        1.0
      Author:         Gonzalo Escajadillo
      Email:          gonzalo.adolfo.escajadillo@ibm.com
      Team:           IBM Cloud
      Creation Date:  14/04/2021
      Purpose/Change: Automation Iniatives
      Script Repository: https://github.ibm.com/ibmcloudperu/azurepublic        
    .EXAMPLE
        PS> RemoveOlderfiles.ps1 -share ('share02')
        20210209-220853-RemoveOlderFiles.log
#>

#[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)] [string] $subscriptionid = 'dd2dbd02-2eb0-46fb-8bdd-1f7d000b1b7e',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountName = 'staccinftab01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory=$false)] [String] $LogStorageAccountContainer = 'logs-backupondemand',
    [Parameter(Mandatory=$false)] [String] $TaskName = "BackupOnDemand",
    [Parameter(Mandatory=$false)] [array]  $TargetFolders = @('database','logs'),
    [Parameter(Mandatory=$false)] [String] $StorageAccountName = "staccodbeu1d01",
    [Parameter(Mandatory=$false)] [String] $StorageAccountRG = 'arsgrsapeu1d01',
    [Parameter(Mandatory=$false)] [String] $vaultName = 'azrsvadbeu1p01',
    [Parameter(Mandatory=$false)] [String] $vaultRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory=$false)] [String] $vaultContainerName = $StorageAccountName,
    [Parameter(Mandatory=$false)] [String] $ShareName = 'crosrvdev'
)

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



#-----------------------------------------------------------[Authentication]------------------------------------------------------------


$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.
$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint



#-----------------------------------------------------------[Functions]------------------------------------------------------------


function RemoveFileDir {  
param (
    [Parameter(Mandatory=$false)][array] $dir,
    [Parameter(Mandatory=$false)][array] $logfile,
    [Parameter(Mandatory=$false)][array] $ShareName,
    [Parameter(Mandatory=$false)][array] $date,
    [Parameter(Mandatory=$false)]$ctx
)

        Write-Output "######################## directory $folder ############### ";
        Write-Output "######################## directory $($dir.name)  ############### ";
            $filelist = Get-AzStorageFile -Directory $dir.CloudFileDirectory 

            foreach ($file in $filelist) {
                $logmessage = '';
                if ($file.GetType().Name -eq "AzureStorageFileDirectory") {
                    RemoveFileDir -dir $file -ctx $ctx -date $date # This is recursion.
                }
                else{
                    $logmessage = "$($dateColumn) - [INFO] - $($file.CloudFile.StorageUri.PrimaryUri.AbsoluteUri) - Eliminando archivo $($file.Name)"
                    Write-Output $logmessage
                    $logmessage | out-file -FilePath $FullLogPath -Append -Force
                    $file.CloudFile | Remove-AzStorageFile 2>&1 | Tee-Object -FilePath $FullLogPath -Append
                }
            }
                $logmessage = "$($dateColumn) - [INFO] - $($dir.CloudFileDirectory.StorageUri.PrimaryUri.AbsoluteUri) - Eliminando directorio $($dir.CloudFileDirectory.Name)"
                Write-Output $logmessage
                $logmessage | out-file -FilePath $FullLogPath -Append  -Force
                $dir.CloudFileDirectory | Where-Object {$dir.CloudFileDirectory.Parent.Name -notlike $null} | Remove-AzStorageDirectory 2>&1 | Tee-Object -FilePath $FullLogPath -Append
}

    
#-----------------------------------------------------------[Execution]-------------------------------------------------------------


Select-AzSubscription -SubscriptionId $subscriptionid
Write-Verbose "subscriptionId: $subscriptionid" -Verbose

$ctx = Set-AzStorageAccount -ResourceGroupName $StorageAccountRG -AccountName $StorageAccountName -Type "Standard_LRS"


#### Backup Process ####

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $vaultRG -Name $vaultname 
$container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $vault.ID -FriendlyName $vaultContainerName 
$backupitem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureFiles -VaultId $vault.ID -FriendlyName  $ShareName 
$backupjob =  Backup-AzRecoveryServicesBackupItem -Item $backupitem -VaultId $vault.ID 
# Clear-Variable -Name newjobstatus
$jobstatus = Get-AzRecoveryServicesBackupJob -JobId $backupjob.JobId -VaultId $vault.ID
Write-Output "Job Status: $($jobstatus.status)"
# Timer
if ($jobstatus.Status -like 'InProgress') { 
    do {
        $newjobstatus = Get-AzRecoveryServicesBackupJob -JobId $backupjob.JobId -VaultId $vault.ID
        Write-Output "####### Timer Loop #######"
        Write-Output "NewJobStatus: $($newjobstatus.Status)"
        sleep 30 
    }
    until ($newjobstatus.Status -notlike 'InProgress')
}
else {
    $newjobstatus = $jobstatus
    Write-Output "Job Status: $($jobstatus.status)"
}

# Start the log file
Write-Output "####### Log started #######"
$logmessage = "$($date) - [INFO] - Inicio de log - $($logfile)"  ;
$logmessage | out-file -FilePath $FullLogPath -Force  ;
$logmessage = '' ;


# Backup Status validation
if ($newjobstatus.status -eq 'Completed'){
 
    Write-Output " ######################## Last Backup Job Detail ###################  "
    Write-Output " Last backup status $($newjobstatus.status) "
    Write-Output $newjobstatus.status
    Write-Output " ######################## Fin Last Backup Job Detail ################ "

    foreach ($folder in $TargetFolders) {
        Write-Output " ######################## FolderName: $($folder) ###################  "
        $Directory = Get-AzStorageFile -Context $ctx.Context -ShareName $ShareName -Path $folder -ErrorAction Continue -Verbose
        Write-Output "Directory: $($Directory.Name)"   

        try {
            RemoveFileDir -dir $Directory -ctx $ctx -logfile $logfile -date $dateColumn -ShareName $ShareName # 2>&1  | Tee-Object -FilePath $FullLogPath -Append
        }
        catch [System.Management.Automation.RuntimeException] {
            Write-Output "######## 1ST Catch Message # $folder ###############  "
            $logmessage =  "$($dateColumn) - [WARN] - Directorio $($folder) - no existe en la raíz del share $ShareName . Recurso no encontrado `n"
            $logmessage | out-file -FilePath $FullLogPath -Append -Force
            $_
        }
        catch {
            Write-Output "######## 2ND Catch Message # $folder ###############  "
            $logmessage = "$($dateColumn) - [ERROR] - +  $($_.exception)"
            Write-Output $logmessage        
            $logmessage | Out-File -FilePath $FullLogPath -Append -Force
            $_ | Out-File -FilePath $FullLogPath -Append -Force
        }
        finally {
            $Error.Clear();
            $logmessage = '';
        }
    }
}
else { # If backup was not completed it will save a error message and it won't remove any file
    Write-Output " ######################## Last Backup Job Detail ###############  "
    Write-Output " The backup job was not completed with Error $($Error[-1].Exception) , review RSV Activity Log for more information "
    Write-Output " The backup job with workloadname  $($backupjob.WorkloadName) fail, review RSV Activity Log for more information "    
    $logmessage = "$($dateColumn) - [ERROR] - $($Error[-1].Exception.InnerException) - The backup job fail with status $($newjobstatus.status) Unknown, review RSV Activity Log for more information `n"
    $logmessage += $Error[-1]
    Write-Output $Error[-1]
    Write-Output $backupjob.WorkloadName
    Write-Output $newjobstatus.status
    $logmessage | Out-File -FilePath $FullLogPath -Force -Append
}



#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullLogPath  -Blob $LogFile -Force -Verbose
