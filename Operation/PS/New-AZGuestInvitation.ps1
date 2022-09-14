# Required: Powershell 5.x 
# Required: AzureAD module
# REquired> AzureAD.Preview
# Required: AzureAD.Standard.Preview (For Cloudshell)
# To review if the module is installed run: Get-Module -ListAvailable AzureAD*
# The Azure AD PowerShell module is not compatible with PowerShell 7. It is only supported in PowerShell 5.1.
# Suggestion: Install and import AzureADPreview 
# Note that you cannot install both the preview version and the GA version on the same computer at the same time.
# https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0#prerequisites


param (
    [Parameter(Mandatory = $false)] [String]  $TenantID = "00193bc8-dddd-41dd-8c93-264763bc0348", 
    [Parameter(Mandatory = $false)] [String]  $SubscriptionID = "d9bc6363-1579-4256-8ac0-7686697ffdb4", 
    [Parameter(Mandatory = $false)] [String]  $WorkingDirectory = ".\AzurePublic\Operation",
    [Parameter(Mandatory = $false)] [String]  $B2BDomain = "kyndryl.com",
    [Parameter(Mandatory = $false)] [string]  $InputFile = "kyndrylUsers.csv",
    [Parameter(Mandatory = $false)] [switch]  $WhatIf 
)

# import-module AzureAD.Standard.Preview
import-module AzureAD
# AzureAD.Standard.Preview\Connect-AzureAD -Identity -TenantId (Get-AzTenant | Where-Object {($_.Name -notlike "IBM*")}).TenantId -AccountId  $azcontext.Account.Id


#------------------------------------------------------------[Declarations]-----------------------------------------------------------


$peruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(([DateTime](Get-Date)).ToUniversalTime(), 'SA Pacific Standard Time')
$date = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$logPath = $(get-location).Path;
$filePath = $(get-location).Path;
$logName = $date + $taskname + '.log'
$fileName = $date + $taskname + '.csv'
$fullLogPath = Join-Path -Path $LogPath -ChildPath $LogName;
$fullFilePath = Join-Path -Path $FilePath -ChildPath $FileName;
$LogDelimiter = ',';
# $cloudb2bcsvPath = "C:\Git\kyndryl\GTS-Cloud-Peru\AzurePublic\Operation\kyndrylUsers.csv"

## auth process ##

$azcontext = Get-azcontext 
Connect-AzureAD -TenantId (Get-AzTenant | Where-Object { ($_.Name -notlike "IBM*") }).TenantId -AccountId  $azcontext.Account.Id

# variables

$tenant = Get-AzTenant -TenantId $TenantID
$csvfile = Import-Csv -Path (gci -File  "*$($InputFile)" | Sort-Object -Descending LastWriteTime)[0] 
$filteredGroups = $csvfile.groupName | Select-Object -Unique
$filteredUsers = $csvfile.Email | Select-Object -Unique

# Create Groups if they doesnt exists
foreach ($group in $filteredGroups) {
    # $groupsArray += Get-AzureADGroup -SearchString $group | Sort-Object DisplayName
    $cloudGroup = Get-AzureADGroup -SearchString $group  | select-object DisplayName, ObjectId # | Sort-Object DisplayName

    # Creates Azure AD Security Group if doesn't exists
    if (!$($cloudGroup)) {
        $cloudGroup = New-AzureADGroup -DisplayName $group -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"
        Write-Output "$($cloudGroup.DisplayName) has been created"
    }    
    else {
        Write-Output "$($cloudGroup.DisplayName) already exists"
    }    
}


# Search for b2b  accounts in azureAD
# Modificar " kyndryl.com" por el parametro b2bdomain
$guestsArrayfilter = Get-AzureADUser -Filter ("UserType eq 'Guest'") -All $true | Where-Object { ($_.UserPrincipalName.Split("#EXT#_",3)[1] -like $($B2BDomain) ) }
# $guestsArrayfilter = $guestsarray | Where-Object { ($_.UserPrincipalName.Split("#EXT#_",3)[1] -like "kyndryl.com" ) }



# Send invitation process
# $guestsArray = Get-AzureADUser -Filter ("UserType eq 'Guest'") -All $true
# $guestsArrayfilter = $guestsarray | select-object UserprincipalName | Where-Object { ($_.UserPrincipalName.Split("#EXT#@", 3) -like "*.kyndryl.com" ) }

# Creates custom invitation message
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
# $messageInfo.customizedMessageBody = "Hello $($guest). You are invited to the  $($azcontext.Name.Split("@",2)[1])  organization."

# Sends Invitation
foreach ($guest in $filteredUsers) {
    if ($guest -notin $guestsarrayfilter) {
        $EventType = '[Information]'
        $messageInfo.customizedMessageBody = "Hello $($guest). You are invited to the  $($tenant.Name) organization."
        $GuestInvite = New-AzureADMSInvitation -InvitedUserEmailAddress $guest -InviteRedirectURL https://myapps.microsoft.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $true
        Add-AzureADGroupMember -ObjectId $cloudgroup.ObjectId -RefObjectId $GuestInvite.InvitedUser.Id
        $logmessage = "$($date) $($LogDelimiter) $($EventType) $($LogDelimiter) $($GuestInvite.InvitedUserEmailAddress) added to the group $($cloudgroup.DisplayName)" 
        Write-Output $message
    }
    else {
        $EventType = '[Information]'
        $logmessage =  "$($date) $($LogDelimiter) $($EventType) $($LogDelimiter) $($guest) is already invited" # | Out-File -Append -Force azureadlog.txt
        Write-Output $message
    }


    $logmessage | Out-File -Append -Force $fullLogPath    
    
}

