#requires -version 2
<#
.SYNOPSIS
  This script will create a PaaS Inventory on CSV format.
.DESCRIPTION
  None
.PARAMETER 
  None
.INPUTS
  None
.OUTPUTS
  Csv file stored in C:\temp\<$date + '-BCP-StorageAccounts>.csv>
  Log file stored in C:\temp\<$date + '-BCP-StorageAccounts>.log>
.NOTES
  Version:        1.0
  Author:         
  Creation Date:  07/06/2019
  Purpose/Change: Initial script development
  Script Code from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags
  Script template from: https://gist.github.com/9to5IT/9620683
  
.EXAMPLE
  .\GetStorageAccountUsage.ps1
#>


param (

    [Parameter(Mandatory=$false)] 
    [String]  $CredentialAssetName = "UsrAzureOperator",

    [Parameter(Mandatory=$false)] 
    [String]  $StorageAccountName = "blobeu2ibmcp01",    

    [Parameter(Mandatory=$false)] 
    [String]  $OutContainer = "inventory-aks",

    [Parameter(Mandatory=$false)] 
    [String]  $TaskName = "-BCP-AKSReport"
)
# $VerbosePreference='Continue'
# $errorActionPreference = "stop"
#$DebugPreference='Continue'


#----------------------------------------------------------[Declarations]-----------------------------------------------------------


[String]  $TenantId = "5d93ebcc-f769-4380-8b7e-289fc972da1b" ;
[String]  $TenantSubscriptionId = "849ecd39-b789-4e32-9c20-726dd3775086" ;
$date = (Get-Date -UFormat "%Y%m%d-%H%M%S").ToString();
$dateColumn = (Get-Date -UFormat "%d/%m/%Y").ToString();
$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;
$LogName = $date + $TaskName + '.log';
$Filename = $date + $TaskName + '.csv';
$FullLogName = Join-Path -Path $LogPath -ChildPath $LogName;
$FullFileName = Join-Path -Path $FilePath -ChildPath $FileName;
$StorageAccountKey = "gDnZspU+sLa9HwqtH4dXEENYRYZ0UFsUG2685+UsIA3V7OiteiABDXvgh79mKcF2yeXGNI9INivVr3dQvK56wg==";

#----------------------------------------------------------[Authentications]--------------------------------------------------------

# Auth##################################################################
# Get the credential with the above name from the Automation Asset store
<#

$GLOBAL:DebugPreference = "Continue"   ## default value is SilentlyContinue  -- This can significantly increase the output.

$Conn = Get-AutomationConnection -Name AzureRunAsConnection; $Conn    
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
write-output (get-azsubscription).name
$AzureContext = Select-AzSubscription -SubscriptionId $conn.subscriptionId; $AzureContext    ## or select a specific subscription
#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------



# Function Get-TimeStamp: Get timestamp for log
function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)   
}

# Function Get-PaaSResources: Get resources inventory
function Get-PaaSAKSResources {
    
    #$resources = Search-AzGraph -Query "Resources | join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId | where type == 'microsoft.containerservice/managedclusters' " -o json | ConvertFrom-Json
    #$resources = az graph query -q "where type == 'microsoft.containerservice/managedclusters' " --include displayNames -o json  | ConvertFrom-Json
    #$resources = az graph  query -q " where type == 'microsoft.containerservice/managedclusters' | project name, subscriptionDisplayName, subscriptionId, properties.kubernetesVersion, properties.agentPoolProfiles[0],resourceGroup, location, tags, type " --include displayNames -o json | ConvertFrom-Json

    $AKSResources = Get-AzAks

    foreach($resource in $AKSResources) {
               
        try{
           

            $obj = [psCustomObject]@{
                'Date' = $dateColumn
                'Subscription' = $subscription.Name
                'SubscriptionId' = $subscription.Id
                'ResourceGroup' = $resource.Id.split('/')[4]
                'Name' = $resource.name
                'Type' = $resource.Type
                'KubernetesVersion' = $resource.KubernetesVersion
                'Nodes' = $resource.AgentPoolProfiles[0].count
                'VMSize' = $resource.AgentPoolProfiles[0].VmSize
                'OsDiskSizeGB' = $resource.AgentPoolProfiles[0].OsDiskSizeGB
                'Project' = $resource.tags.Proyecto
                'Support' = $resource.tags.Operación
                'Operation' = $resource.tags.operation
                'CodApp' = $resource.tags.COD_APP
                }
            $obj | Export-Csv -notypeinformation -Path $FullFileName -Encoding UTF8 -Append ;
            

        }
        catch [Exception]{
            
            $LogMessage += "$(Get-TimeStamp)  $PSitem.Exception "  | Out-File $FullLogName -Append utf8 -Force ;
            $LogMessage += ("$(Get-TimeStamp)" + "  Recurso: " + $resource.name)  | Out-File $FullLogName -Append utf8 -Force ;
            echo $PSItem |format-list -force | Out-File $FullLogName -Append utf8 -Force ;            
            
        }
    }
}



#-----------------------------------------------------------[Execution]-------------------------------------------------------------


# Run on all supported subscriptions
$subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled')}

<#
# Try on 2 subscriptions MNYR y PRTI
$subscriptions = Get-AzSubscription | Where-Object { ($_.SubscriptionId -like 'dd17682d-ca91-4f56-ac66-e174635de6a4' -or `
            $_.SubscriptionId -like '84d095d4-87ce-4525-a99e-46fa262a242e') }
#>

foreach ($subscription in $subscriptions) {
    Select-AzSubscription -SubscriptionId $subscription.Id  
    Get-PaaSAKSResources 
    
}


#-------------------------------------------------------------[Output]--------------------------------------------------------------


$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Set-AzStorageBlobContent -Container $OutContainer -File $FullFileName -Force -Confirm:$false -Context $ctx
Set-AzStorageBlobContent -Container $OutContainer -File $FullLogName -Force -Confirm:$false -Context $ctx 

Write-Output $ctx



