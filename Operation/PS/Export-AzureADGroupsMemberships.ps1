#Requires -Version 3
# Requires Powershell 5.x 
# Required: AzureAD module
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
      Email:	      gonzalo.adolfo.escajadillo@kyndryl.com
      Team:           Cloud
      Creation Date:  28/04/2022
      Purpose/Change: Automation Iniatives
      Script Repository: https://github.kyndryl.com/GTS-Cloud-Peru/AzurePublic/Operation	
#>


#[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)] [String]  $TenantID = "00193bc8-dddd-41dd-8c93-264763bc0348", 
    [Parameter(Mandatory = $false)] [String]  $SubscriptionID = "d9bc6363-1579-4256-8ac0-7686697ffdb4", 
    [Parameter(Mandatory = $false)] [String]  $CustomerName = "GenesisEcuador",    
    [Parameter(Mandatory = $false)] [String]  $TaskName = "KyndrylUsers",
    [Parameter(Mandatory = $false)] [String]  $B2BDomain = "kyndryl.com",
    [Parameter(Mandatory = $false)] [String]  $LogStorageAccountName = 'staccinftab01',
    [Parameter(Mandatory = $false)] [String]  $LogStorageAccountRG = 'arsgrinfeu1p01',
    [Parameter(Mandatory = $false)] [String]  $LogStorageAccountContainer = 'logs-vmsinventory',    
    [Parameter (Mandatory = $false)] [object] $WebhookData
)
# $VerbosePreference='Continue'
# $errorActionPreference = "stop"
$DebugPreference = 'Continue' ## default value is SilentlyContinue  -- This can significantly increase the output.


#------------------------------------------------------------[Declarations]-----------------------------------------------------------


$peruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(([DateTime](Get-Date)).ToUniversalTime(), 'SA Pacific Standard Time')
$date = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$logPath = $(get-location).Path;
$filePath = $(get-location).Path;
$logName = $date + "-$($taskname)" + '.log'
$fileName = $taskname + '.csv'
$fullLogPath = Join-Path -Path $LogPath -ChildPath $LogName;
$fullFilePath = Join-Path -Path $FilePath -ChildPath $FileName;
$customRoles = @()
$global:userArray = @()


#-----------------------------------------------------------[Authentication]----------------------------------------------------------


$azcontext = Get-AzContext  

#$context = Get-AzContext

if ($context.Subscription.Id -ne $SubscriptionId) {
    Connect-AzureAD -TenantId (Get-AzTenant  -TenantId $TenantID ) -AccountId  $azcontext.Account.Id
    Select-AzSubscription  -subscriptionid  $SubscriptionId
    Write-Output "Authenticated in tenant: $($context.Tenant.Id)"
} 
else {
    Write-Output "SubscriptionId $($context.Subscription.Id) already connected"
}


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function BuildUserPermissions {
    param (
        $Group,
        $groupmembers,
        $groupAssignments
    )

    Write-Output "Starting BuildUserPermissions function"
 
    foreach ($member in $groupmembers) {

        #        $roleDefinition = $customRoleDefinitions | Where-Object -Property Name -Like "$($groupAssignment.RoleDefinitionName)"
        foreach ($groupAssignment in $groupAssignments) {          
            $groupAssignment.DisplayName | % {
                $userObj = [pscustomobject]@{
                    'GroupName'   = $group.DisplayName
                    'DisplayName' = $member.DisplayName
                    'Email'       = $($member.UserPrincipalName.Split("#EXT#@", 2)[0]).replace("_", "@")
                    'Role'        = $groupAssignment.RoleDefinitionName
                } 
                Write-Output "Print inside function $($userObj)"
                $global:userArray += $userObj
                Write-Output "Print global userArray $($global:userArray)"
            }
        }
    }
}
   
    

#-----------------------------------------------------------[Execution]-------------------------------------------------------------


Write-Output "Starting Process"
# Used to export users from 
$ADGroups = Get-AzureADGroup
# $customRoles = Get-AzRoleDefinition | Where-Object -Property IsCustom -like $true 
$customRoleAssignments = Get-AzRoleAssignment | Where-Object -Property ObjectType -like Group | Select-Object DisplayName, RoleDefinitionName, RoleDefinitionId



# $customRoleDefinitions = $customRoleAssignment  | ForEach-Object {Get-AzRoleDefinition -Name $_.RoleDefinitionName }
# Get-AzRoleDefinition -Name $customRoleAssignment[0].RoleDefinitionName

foreach ($group in $ADGroups) {
    $groupAssignments = $customRoleAssignments | Where-Object -Property DisplayName -Like $group.DisplayName
    $groupmembers = Get-AzureADGroupMember -ObjectId $group.ObjectId | Where-Object { ("UserType eq 'Guest'") -and ($_.UserPrincipalName.Split("#EXT#_", 3)[1] -like $($B2BDomain) ) }
    # $customRoleDefinitions  | Where-Object -Property DisplayName -Like $group.DisplayName

    BuildUserPermissions -Group $group  -groupmembers $groupmembers -groupAssignments $groupAssignments
}
#>



#-------------------------------------------------------------[Output]--------------------------------------------------------------

if (!($userArray)) {
    Write-Output "Something has fail, check paremeters and try again" 
} `
    else {
    Write-Output "The file was generated successfully"
    $userArray | Export-Csv -NoTypeInformation $fullFilePath    
}


