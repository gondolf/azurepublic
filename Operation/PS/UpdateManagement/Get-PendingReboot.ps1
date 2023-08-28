# Powershell 7
<#
.SYNOPSIS
This script performs XYZ operations.

.DESCRIPTION
This script does...

.NOTES
File Name      : Get-PendingReboot.ps1
Author         : Gonzalo Escajadillo
Prerequisite   : Windows PowerShell 7
Copyright 2023 - Kyndryl

.LINK
Script Source: https://github.com/yourusername/yourrepo

#Requires -Version 7.0
#>

#----------------------------------------------------------[Parameters]-----------------------------------------------------------
param (
    [Parameter(Mandatory = $false)] [String]  $resourceId = "/subscriptions/8bacf08c-ed66-4a7f-9c82-af1ce9a68cce/resourceGroups/rgumcdemo01/providers/Microsoft.Compute/virtualMachines/vmlnx1",
    [Parameter(Mandatory = $false)] [ValidateSet('Linux', 'Windows')] [String]$osType = 'Linux'
)

#----------------------------------------------------------[Declarations]-----------------------------------------------------------

$aacidentity = "aavarmanidumcdemo01" ;
$VariableValue = Get-AutomationVariable -Name $($aacidentity) ;
# Write-output $VariableValue
# Split the resource id to get the vm name
$vmName = $resourceId.Split('/')[-1] ;
# Split the resource id to get the resource group name
$rgName = $resourceId.Split('/')[4] ;
# Split the resource id to get the subscription id
$subscriptionId = $resourceId.Split('/')[2] ;

$linuxScriptchain = "needs-restarting -r"
$windowsScriptchain = @'
  function Test-PendingReboot {
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress" -EA Ignore) { return $true }
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
    try { 
      $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
      $status = $util.DetermineIfRebootPending()
      if(($status -ne $null) -and $status.RebootPending){
        return $true
      }
    }catch{}
    return $false
  }
  Test-PendingReboot
'@
$VMarray = @();
$objArray = @();


#---------------------------------------------------------[Authentication]-----------------------------------------------------------

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process > $null;

# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $($VariableValue)).context > $null;

# set and store context
$AzureContext = Set-AzContext -SubscriptionId $subscriptionId -DefaultProfile $AzureContext > $null;



#-----------------------------------------------------------[Execution]-------------------------------------------------------------
# Get the VM 
$vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName

# if ostype is linux, run the linux script $linuxscriptchan if not run the windows script $windowsScriptchain 
if ($osType -eq 'Linux') {
    $message = (Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name `
                -CommandId 'RunShellScript' -ScriptString "$($linuxScriptchain)").Value[0].Message ; 
                #if $message starts with "Reboot is required", then set $rebootrequest to true, else set it to false
                if ($message -like "*Reboot is required*") { 
                    $rebootrequest = $true ;
                    # Write-Output "Linux Reboot is required"
                } else { 
                    $rebootrequest = $false ;
                    # Write-Output "Linux Reboot is not required"
                }                
}
else {
    $message = (Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name `
                -CommandId 'RunPowerShellScript' -ScriptString "$($windowsScriptchain)").Value[0].Message ; 
                if ($message -contains 'True') { 
                    $rebootrequest = $true ;
                    # Write-Output "Windows Reboot is required"
                }
                else { 
                    $rebootrequest = $false ;
                    # Write-Output "Windows Reboot is not required"
                }     
}
$key = 'Status' ;
$value = "$($rebootrequest)" ;
$objArray = ([pscustomobject] @{key = $key; value = $value }) ;
Write-Output ($objArray | ConvertTo-Json) ;
