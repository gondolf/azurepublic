#Requires -version 3

<#
    .SYNOPSIS
        This script can be used to monitor Azure Stack Services
    .DESCRIPTION
        The script execute some modules to get the main  azure stack service health
        The result will be logged as an event in windows event viewer and also it will be log in a txt file (you can comment just those lines if does not require them)
        The process will send an email alert when some service appears unhealthy
        The process should be schuduled with windows task manager
        The script use a function to force a proxy setup to allow authentication to azure through this proxy.
        This script requires an key and  text file as input to authenticate with azure ad credentials.
    .PARAMETER SubscriptionId
        Specifies the subscription ID. 
    .PARAMETER LogShare
        Specifies the share that will be used to save the operation logs.
    .INPUTS
        $KeyFile =  "spn_svribmcmon01.key"
        $PasswordFile =  "spn_svribmcmon01.txt"
    .OUTPUTS
        System.String. RemoveOlderfiles.ps1 returns a string with the log for the operation.
        System.String. $date + '-' + $TaskName +'.csv'
    .NOTES
      Version:        1.0
      Author:         Gonzalo Escajadillo 
                      Richard Campos
      Email:          gonzalo.adolfo.escajadillo@ibm.com
                      rjcampos@pe.ibm.com
      Team:           IBM Cloud
      Creation Date:  14/04/2021
      Purpose/Change: Automation Iniatives
      Script Repository: https://github.ibm.com/ibmcloudperu/azurepublic
    .EXAMPLE
        PS> .\Az-WebPostDeployment.ps1 -SystemLabels "Pagination','Aplications" -TimeZone "SA Pacific Standard Time"
        PS> .\Az-WebPostDeployment.ps1
#>


param (
    [Parameter(Mandatory=$false)] [Array]   $SystemLabels = @('Pagination','Applications'),
    [Parameter(Mandatory=$false)] [string]  $TimeZone = "SA Pacific Standard Time"
)

#-----------------------------------------------------------[Declarations]-----------------------------------------------------------


#-----------------------------------------------------------[Authentication]------------------------------------------------------------


#-----------------------------------------------------------[Functions]---------------------------------------------------------------


#-----------------------------------------------------------[Execution]-------------------------------------------------------------


# Identifica las unidades de paginación y aplicaciones
$volumenes = Get-Volume | Where-Object {$_.FileSystemLabel -in $SystemLabels}
foreach ($volume in $volumenes) {

    if($volume.FileSystemLabel -like 'Pagination'){
        $pagedisk = $volume
    }
    elseif ($volume.FileSystemLabel -like 'Applications'){
        $appdisk = $volume
    }
}
    
# Asigna una unidad temporal y luego asigna la unidad especifica
Set-Partition -DriveLetter $pagedisk.DriveLetter -NewDriveLetter 'X'
Set-Partition -DriveLetter $appdisk.DriveLetter -NewDriveLetter 'Y'
Set-Partition -DriveLetter 'X' -NewDriveLetter 'P'
Set-Partition -DriveLetter 'Y' -NewDriveLetter 'E'

# Elimina la configuración de paginación en caso sea administrado por el O.S.
$pagefiles = Gwmi win32_pagefilesetting 
foreach ($pagefile in $pagefiles){
    $pagefile.Delete()
}

# Configura la paginación de forma dinámica
Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{name="P:\pagefile.sys";
InitialSize = 0; MaximumSize = 0} -EnableAllPrivileges  | Out-Null

# Configura la zona horaria
Set-TimeZone -Name $TimeZone

# Force domain policies
gpupdate /force

#-----------------------------------------------------------[Output]-------------------------------------------------------------


