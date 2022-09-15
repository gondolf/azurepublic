#Use a filter to select resource groups by substring
$filter = 'company'
 
#Find Resource Groups by Filter -> Verify Selection
$selectedResourceGroups = Get-AzResourceGroup | ? ResourceGroupName -match $filter | Select-Object ResourceGroupName

#Show Resource Groups to be deleted
Write-Output $selectedResourceGroups

#!!!#
#Continue only if you are sure...

<#
$PSARMObject = [PSCustomObject]@{
    '$Schema' = 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
    contentVersion = '1.0.0.0'
    resources = @()
}


ConvertTo-Json -InputObject $PSARMObject | ConvertFrom-Json -AsHashtable
Write-Output $emptyARMTemplate
#>


$emptyARMTemplate = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#'
    contentVersion = '1.0.0.0'
    resources = @()
    }


# $TemplateObject = ConvertFrom-Json $emptyARMTemplate -AsHashtable

 
Write-Output $TemplateObject
#>

#Execution
Write-Output "Starting loop" 
foreach ($g in $selectedResourceGroups.ResourceGroupName) {
    Write-Output "ResourceGroupName: $($g)"
    # New-AzResourceGroupDeployment -Name PurgeResourceGroup -ResourceGroupName $($g) -TemplateObject $emptyARMTemplate -Mode Complete -Force
    Remove-AzResourceGroup -Name $g -Force 
}
