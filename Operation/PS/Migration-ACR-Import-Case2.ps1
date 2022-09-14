$username = "kyndryl@promartdigital.pe"
$password = "S0p0rt3@123"
$targetregistry = "tpsahubqa"

az login -u $username -p $password -o none

$stringrepo = @()

foreach($line in Get-Content .\SRepositories.txt)
    {
        $stringrepo = $line.Split(":")
        $stringrepo[0]
        $breakfor = "not"

        [System.Collections.ArrayList]$targetrepos = @()
        $targetrepos = az acr repository list --name $targetregistry -o json | ConvertFrom-Json

        for ($j = 0; $j -lt $targetrepos.Count; $j++)
            {
                if ($stringrepo[0] -eq $targetrepos[$j])
                {
                    if($breakfor -eq "not")
                    {
                        $targettags = az acr repository show-tags --name $targetregistry --repository  $targetrepos[$j]  | ConvertFrom-Json
                        Switch ($targettags.GetType().Name)
                        {
                            "Object[]"
                            {
                                [System.Collections.ArrayList]$totaltags = @()
                                $totaltags = $targettags

                                for ($k = 0; $k -lt $totaltags.Count; $k++)
                                    {
                                        [String]$stringrepotag = ""
                                        $stringrepotag = "$($targetrepos[$j]):$($totaltags[$k])"
                                        
                                            if ($line -eq $stringrepotag)
                                            {
                                                "Son iguales: $line y $stringrepotag"
                                                $breakfor="yes"
                                                break
                                            }else {
                                                "No son iguales: $line y $stringrepotag"
                                            }
                                    }
                            }
                            "String"
                            {
                                [String]$stringrepotag = ""
                                $stringrepotag = "$($targetrepos[$j]):$($targettags)"
                                if ($line -eq $stringrepotag)
                                    {
                                        "Son iguales: $line y $stringrepotag"
                                        $breakfor="yes"
                                        break                                    
                                    }else {
                                        "No son iguales: $line y $stringrepotag"
                                    }
                            }
                        }
                    }
                    else {
                        break
                    }
                }
            }
    }