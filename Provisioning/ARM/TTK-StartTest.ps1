$ttkpath = "C:\GiT\gondolf\arm-ttk\arm-ttk\"
$TemplateToAnalyze = "C:\git\kyndryl\GTS-Cloud-Peru\UNIQUE\MANAGE\AZURE\ARM\CLUSTER-WIN-BaseLine-AS\azuredeploy.json"
$modulepath = $($ttkpath) + "arm-ttk.psd1"

Import-Module $modulepath # assuming you're in the same directory as .\arm-ttk.psd1

Test-AzTemplate -TemplatePath $TemplateToAnalyze -Test deploymentTemplate 
# This will run deployment template tests on all appropriate files
<# There are currently four groups of tests:
    * deploymentTemplate (aka MainTemplateTests)
    * deploymentParameters
    * createUIDefinition
    * all
#>
