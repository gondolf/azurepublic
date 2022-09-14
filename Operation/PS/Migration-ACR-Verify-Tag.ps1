$username = "kyndryl@homecentersperuanos.onmicrosoft.com"
$password = "S0p0rt3@123"
$sourceregistry = "hubtpsa"
#$targetregistry = "hpsahub"

az login -u $username -p $password -o none

$sourcerepos = az acr repository list --name $sourceregistry -o json | ConvertFrom-Json

foreach($srepo in $sourcerepos)
    {
        $sourcetags = az acr repository show-tags --name $sourceregistry --repository $srepo  | ConvertFrom-Json

        foreach($stag in $sourcetags)
        {
            $mdtag = az acr repository show -n $sourceregistry --image "$($srepo):$($stag)" | ConvertFrom-Json
            
            [pscustomobject] @{"Repo.Name" = $srepo ; "Tag.Name" = $mdtag.Name ; "Tag.CreationDate" = $mdtag.createdTime }
            | Export-Csv -Path .\Tag-hubtpsa.csv -Append -Encoding utf8BOM
        }
    }