# Import module
Import-Module PSDocs.Azure;

# Scan for Azure template file recursively in the templates/ directory
Get-AzDocTemplateFile -Path templates/ | ForEach-Object {
    # Generate a standard name of the markdown file. i.e. <name>_<version>.md
    $template = Get-Item -Path $_.TemplateFile;
    $currentpath = $template.Directory.FullName
#    $templateName = $template.Directory.Parent.Name;
#    $version = $template.Directory.Name;
#    $docName = "$($templateName)_$version";
    $docName = 'README'

    # Generate markdown
    Invoke-PSDocument -Module PSDocs.Azure -OutputPath $currentpath -InputObject $template.FullName -InstanceName $docName;
}