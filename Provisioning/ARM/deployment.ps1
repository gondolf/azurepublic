param (
    [Parameter(Mandatory = $false)] [String]  $TenantId = "78153f1a-b836-436b-b9bb-281f4fe2d1d0",
    [Parameter(Mandatory = $false)] [String]  $Subscriptionid = "8bacf08c-ed66-4a7f-9c82-af1ce9a68cce",
    [Parameter(Mandatory = $false)] [String]  $ResourceGroupName = '1-99e8c8c0-playground-sandbox', # Only for Resourcegroup deployments
    [Parameter(Mandatory = $false)] [String]  $WorkingDirectory = ".\templates\4 infrabase\",
    [Parameter(Mandatory = $false)] [string]  $TemplateFile = $WorkingDirectory + "\azuredeploy.json",
    [Parameter(Mandatory = $false)] [String]  $TemplateParameterFile = $WorkingDirectory + "\azuredeploy.parameters.json",
    [Parameter(Mandatory = $false)] [switch]  $SubscriptionDeployment ,
    [Parameter(Mandatory = $false)] [string]  $Location = "eastus2" ,
    [Parameter(Mandatory = $false)] [switch]  $WhatIf 
)


$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

#$DebugPreference = 'SilentlyContinue' #'Continue'
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
        New-AzResourceGroupDeployment -Name "OnDemandDeployment" -ResourceGroupName $ResourceGroupName -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile  -DeploymentDebugLogLevel All -WhatIf
    
    }
    else {
        Write-Output "whatIf $($false)"
        New-AzResourceGroupDeployment -Name "OnDemandDeployment" -ResourceGroupName $ResourceGroupName  -Location $Location -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile  -DeploymentDebugLogLevel All
    }    
}




