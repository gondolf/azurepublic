param (
    [Parameter(Mandatory = $false)] [String]  $TenantId = "3617ef9b-98b4-40d9-ba43-e1ed6709cf0d",
    [Parameter(Mandatory = $false)] [String]  $Subscriptionid = "964df7ca-3ba4-48b6-a695-1ed9db5723f8",
    [Parameter(Mandatory = $false)] [String]  $ResourceGroupName = "$((Get-AzResourceGroup).ResourceGroupName)", # Only for Resourcegroup deployments
    [Parameter(Mandatory = $false)] [String]  $WorkingDirectory = ".\templates\11 test\",
    [Parameter(Mandatory = $false)] [string]  $TemplateFile = $WorkingDirectory + "\azuredeploy.json",
    [Parameter(Mandatory = $false)] [String]  $TemplateParameterFile = $WorkingDirectory + "\azuredeploy.parameters.json",
    [Parameter(Mandatory = $false)] [switch]  $SubscriptionDeployment ,
    [Parameter(Mandatory = $false)] [string]  $Location = "eastus" ,
    [Parameter(Mandatory = $false)] [switch]  $WhatIf 
)


$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

# $DebugPreference = 'Continue' 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
function Login ($SubscriptionId, $TenantId) {
    $context = Get-AzContext

    if ($context.Subscription.Id -ne $SubscriptionId) {
        Connect-AzAccount -TenantId $TenantId
        Select-AzSubscription  -subscriptionid  $SubscriptionId
        Write-Output "Authenticated in tenant: $($context.Tenant.Id)"
    } 
    else {
        Write-Output "SubscriptionId $($context.Subscription.Id) already connected"
    }
}

Login -SubscriptionId $SubscriptionId -TenantId $TenantId


if ($SubscriptionDeployment) {
    if ($WhatIf.IsPresent) {
        Write-Output "Whatif $($true)"
        New-AzSubscriptionDeployment -Name 'SubscriptionDeployment' -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -DeploymentDebugLogLevel All -WhatIf
    
    }
    else {
        Write-Output "whatIf $($false)"
        New-AzSubscriptionDeployment -Name 'SubscriptionDeployment' -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -DeploymentDebugLogLevel All
    }      
}
else {
    if ($WhatIf.IsPresent) {
        Write-Output "Whatif $($true)"
        New-AzResourceGroupDeployment -Name "OnDemandDeployment" -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile  -DeploymentDebugLogLevel All -WhatIf
    
    }
    else {
        Write-Output "whatIf $($false)"
        New-AzResourceGroupDeployment -Name "OnDemandDeployment" -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile  -DeploymentDebugLogLevel All
    }    
}