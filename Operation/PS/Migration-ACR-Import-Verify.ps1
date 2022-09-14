$username = "kyndryl@promartdigital.pe"
$password = "S0p0rt3@123"
$sourceregistry = "hpsahubqa"
$targetregistry = "hpsahub"

az login -u $username -p $password -o none

$sourcerepos = az acr repository list --name $sourceregistry -o json | ConvertFrom-Json

foreach($srepo in $sourcerepos)
    {
        #$stringrepo = $line.Split(":")
        #$breakfor = "not"

        [System.Collections.ArrayList]$targetrepos = @()
        $targetrepos = az acr repository list --name $targetregistry -o json | ConvertFrom-Json

        if ($targetrepos -match $srepo)
        {
            "Found $srepo"
            Add-Content .\Found_Repository.txt -Value $srepo
        }else{
            "Not Found $srepo"
            Add-Content .\NoFound_Repository.txt -Value $srepo
        }
    }