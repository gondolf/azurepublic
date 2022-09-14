#requires -version 2
<#
.SYNOPSIS
  This script will create a csv file with information about historical backup jobs status for each Recovery Service Vault Job
.DESCRIPTION
  This runbook will generate a csv file with information about job status for the last 29 days for each recovery service vault on each subscription.
.PARAMETER TenantId
  None
.PARAMETER CredentialAssetName
  None
.PARAMETER JobHistory
  Represents the amount of days for the job history report query
.PARAMETER OutContainer
  The storage account container that will be used to save the csv file, by default "inventory-backups" will be used
.PARAMETER TaskName
  This filed will be used to concatenate the the csv and log filenames, by default "-BCP-BackupStatusReport" will be used
.INPUTS
  WEBHOOKDATA Used if the runbook was invoked by a webhook, it must include jobhistory parameter
.OUTPUTS
  Script CSV file will be stored on the storage account
  Temporal HTML Webpage at $storageaccount log container path
.NOTES
  Version:        1.0
  Author:         Gonzalo Escajadillo
  Email:          gonzalo.adolfo.escajadillo@ibm.com
  Team:           IBM Cloud
  Creation Date:  14/04/2021
  Purpose/Change: Automation Iniatives
  Script Repository: https://github.ibm.com/ibmcloudperu/azurepublic
.EXAMPLE
  .\AZ-BackupStatus.ps1
#>


# Returns strings with status messages
# [OutputType([String])]

param (

    [Parameter(Mandatory=$false)] [String]  $SubscriptionId = 'dd2dbd02-2eb0-46fb-8bdd-1f7d000b1b7e',
    [Parameter(Mandatory=$false)] [String]  $JobHistory = "1",
    [Parameter(Mandatory=$false)] [String]  $TaskName = "backupstatusreport",
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountName = 'staccinftab01',
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory=$false)] [String]  $LogStorageAccountContainer = "logs-$($TaskName)",
    [Parameter (Mandatory=$false)] [object] $WebhookData

)

# $errorActionPreference = "stop"
$DebugPreference='Continue'



#----------------------------------------------------------[Declarations]-----------------------------------------------------------

$Customer = 'Crosland'
$DateTime  = ([DateTime](Get-Date)).ToUniversalTime()
$PeruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, 'SA Pacific Standard Time')
$FileTime = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$LogTime = (Get-Date $PeruTime -DisplayHint Time).DateTime.ToString()
$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;
$OutcomeFile = $Customer + '-' + $TaskName + '-' + 'Azure' + '.csv';
$LogFile = $Customer + '-' + $TaskName + '-' + 'Azure' + '.log';
$FullOutcomePath = Join-Path -Path $LogPath -ChildPath $OutcomeFile;
$FullLogPath = Join-Path -Path $LogPath -ChildPath $LogFile;

# Variables for Web Output
$global:JobArray = @()
$WebFile = 'index.html';
$WebPath = $(get-location).Path;
$FullWebPath = Join-Path -Path $WebPath -ChildPath $WebFile;
$WebStorageAccountContainer = '$web'
#### Webhook #####
$TipoBackup = 'Online'

# Listado de subscripciones no administrados
$SubscriptionsUnmanaged = @(
    'SUB-DEV-01',
    'SUB-QAS-01'
)



#----------------------------------------------------------[Authentications]--------------------------------------------------------


$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.

$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
#>


#-----------------------------------------------------------[Functions]------------------------------------------------------------


# Function Get-TimeStamp: Get timestamp for log
function Get-TimeStamp {
param($Time)
    return "{0:dd/MM/yy} {0:HH:mm:ss}" -f $($Time) 
}

# Function to get BackupJobStatus
Function Get-BackupJobStatus {
param(
    $subscription,
    $vault,
    $Time,
    $JobHistory,
    $TipoBackup
)
      
    $Workloads = Get-AzRecoveryServicesBackupJob -From (Get-Date).AddDays(-$JobHistory).ToUniversalTime() -VaultId $vault.ID -ErrorAction Continue
    $Resource = Get-AzResource -ResourceId $vault.ID  | Select-Object Tags  
    foreach ($workload in $workloads){
        write-output $workload
        $JobObj = [pscustomobject]@{
#                    'Fecha' = (Get-TimeStamp -Time $Time)
                    'Hostname' = $workload.workloadName
                    'Label' = $workload.workloadName
#                    'Subscripcion' = $subscription.Name
#                    'Proyecto' = $Resource.Tags['Proyecto']
#                    'Operacion' = $Resource.Tags['Operación']                    
                    'HoraInicio' = $workload.StartTime.ToString("dd/MM/yyyy HH:MM:ss")
                    'HoraFin' = $workload.EndTime.ToString("dd/MM/yyyy HH:MM:ss")
                    'Duracion' = ("{0:hh\:mm\:ss}" -f $(($Workloads[0].Duration)))
                    'Estado' = $workload.Status
                    'TipoBackup' = $TipoBackup
                    'Ubicacion' = $workload.BackupManagementType
#                    'Error' = $workload.ErrorDetails.ErrorMessage
            }
            $global:JobArray += $JobObj
            $JobObj | Export-Csv -NoTypeInformation -Path $FullOutcomePath -Encoding UTF8 -Append -Force
        }
}




#-----------------------------------------------------------[Execution]-------------------------------------------------------------


if ($WebhookData -ne $null) {
    Write-output " ### The runbook was invoked by a webhook ####"
    write-output $webhookdata 

    # Get the info needed to identify the VM (depends on the payload schema)
    $schemaId = $WebhookBody.schemaId
    Write-output  " SchemaId: $schemaId"
    
        
    # Check header for message to validate request
    if ($WebhookData.RequestHeader.message -eq 'StartedbyServicePortal')
    {
        $message = "Header has required information"
        Write-output $message
        $logmessage = "$($date) - [INFO] - $($message) - Status: $($status)"  ;
        $logmessage | out-file -FilePath $FullLogPath -Force  ;          
        $status = "Activated"
        Write-output " Status: $($status)"
    }
    else
    {
        $message = "Header missing required information";
        Write-Output $message
        $status = "Null"
        $logmessage = "$($date) - [INFO] - $($message) - Status: $($status)"  ;
        $logmessage | out-file -FilePath $FullLogPath -Force  ;        
        exit;
    } 

    # Collect properties of WebhookData
    $WebhookName 	= 	$WebhookData.WebhookName
    $WebhookHeaders = 	$WebhookData.RequestHeader
    $WebhookBody 	= 	$WebhookData.RequestBody

    # Collect individual headers converted from JSON.
    $WebhookHistory = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

    # Print webhook variables:
    Write-output "WebhookName: $($WebhookName)"
    Write-output "WebhookHeaders: $($WebhookHeaders)"
    Write-output "WebhookBody: $($WebhookBody)"
    Write-output "JobHistory: $($WebhookData.RequestBody)"  
    Write-Output "Runbook started from webhook $WebhookName ."
    Write-output "JobHistory from webhookdata: $($WebhookHistory.jobhistory)"

    $WebhookHistory.jobhistory

    if (($status -eq "Activated") -or ($status -eq "Fired")) {
        # Start the log file
        $logmessage = "$($date) - [INFO] - Inicio por Webhook - $($logfile)"  ;
        $logmessage | out-file -FilePath $FullLogPath -Force  ;
        $logmessage = '' ;                
        Write-output "Subscription ID: $($SubId)"
        $vaults = Get-AzRecoveryServicesVault
        foreach ($vault in $vaults){
            Get-BackupJobStatus -vault $vault -JobHistory $WebhookHistory.jobhistory -Time $PeruTime -TipoBackup $TipoBackup
        }
        ## Convert the JobArray to html website
        $global:JobArray | ConvertTo-Html -As Table | Out-File $FullWebPath -Force
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
        $vaults = Get-AzRecoveryServicesVault
        foreach ($vault in $vaults){
            Get-BackupJobStatus -vault $vault -JobHistory $JobHistory -Time $PeruTime -subscription $subscription -TipoBackup $TipoBackup
        }
        ## Convert the JobArray to html website
        $global:JobArray | ConvertTo-Html -As Table | Out-File $FullWebPath -Force
    }

    else {
        # Run on all supported subscriptions
        $subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled') -and ($_.Name -notin $SubscriptionsUnmanaged)} | select Name, Id, State
        write-output = ($subscriptions).Count

        foreach ($subscription in $subscriptions) {
            if ($subscription.State -ne "Disabled") {
                Select-AzSubscription -SubscriptionId $subscription.Id  

                $vaults = Get-AzRecoveryServicesVault
                foreach ($vault in $vaults){
                    Get-BackupJobStatus -vault $vault -JobHistory $JobHistory -Time $PeruTime -subscription $subscription -TipoBackup $TipoBackup
                }
            }
        }
    }
}


#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $logfile into a storage account blob used for logs.
$ctxlog = Set-AzStorageAccount -ResourceGroupName $LogStorageAccountRG -AccountName $LogStorageAccountName -Type "Standard_LRS"
Write-Output $ctxlog.Context
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $LogStorageAccountContainer -File $FullOutcomePath  -Blob $OutcomeFile -Force -Verbose


# Upload index.html blob to storage account
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $WebStorageAccountContainer -File $FullWebPath  -Blob $WebFile -Force -Verbose -Properties @{"ContentType" = "text/html"}
Write-Output $ctxlog.PrimaryEndpoints.Web
