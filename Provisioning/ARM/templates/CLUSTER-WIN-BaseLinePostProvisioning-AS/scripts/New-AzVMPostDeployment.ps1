param (
    [Parameter(Mandatory = $false)] [Array]   $SystemLabels = @('Pagination', 'Applications', 'Temporary Storage'),
    [Parameter(Mandatory = $false)] [string]  $TimeZone = "SA Western Standard Time",
    [Parameter(Mandatory = $false)] [switch] $DisableFW = $true,
    [Parameter(Mandatory = $false)] [string]  $Appletter = "E",
    [Parameter(Mandatory = $false)] [string]  $Pageletter = "P"
)

$Global:Pagedisk = $null
$Global:Appdisk = $null

# Deshabilita firewall de windows
if ($DisableFW -like $true) {
    Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled false
    }


# Configura la zona horaria
Set-TimeZone -Name $TimeZone

# Set CD/DVD Drive to Z:
$cd = $NULL
$cd = Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:COMPUTERNAME -ErrorAction Stop 
if ($cd.Drive -eq "E:")
{
   Write-Output "Changing CD Drive letter from E: to Z:"
   Set-WmiInstance -InputObject ( Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'E:'" ) -Arguments @{DriveLetter='Z:'}
}
else {
    Write-Output " CD Drive is not using drive letter E, or is not connected "
}


$disk = Get-Disk | Where-Object { $_.PartitionStyle -like 'RAW' } | sort number
Write-Output "Discos: $($disk)"
# Clear-Disk -Number 2
# Check for Non Initialized disks to format
if ($disk.DiskNumber -like 2) {
    Write-Output "Inicializando disco $($SystemLabels[1])"
    $disk | Initialize-Disk -PartitionStyle GPT -PassThru | 
    New-Partition -UseMaximumSize -DriveLetter $Appletter | 
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SystemLabels[1])" -Confirm:$false -Force
}
else {
    Write-Output "No hay discos sin formato"
}


function GetVolumes  ($SystemLabels) {

    $Global:Pagedisk = $null
    $Global:Appdisk  = $null

    # Identifica las unidades de paginación y aplicaciones
    $volumenes = Get-Volume | Where-Object { $_.FileSystemLabel -in $SystemLabels }
    foreach ($volumen in $volumenes) {
        #$volumen.DriveLetter
        
        if ( $volumen.FileSystemLabel -like $($SystemLabels[2]) ) {
            $Global:pagedisk = $volumen.DriveLetter
            Write-Output "en el if: $($volumen.DriveLetter)"
            # $volumen.DriveLetter
        }
        else{ 
            $Global:appdisk = $volumen.DriveLetter
            Write-Output "en el else: $($volumen.DriveLetter)"
            # $volumen.DriveLetter
        }
    }
}

    

# Obtiene las letras de las unidades de paginacion y aplicacion
GetVolumes -SystemLabels $SystemLabels

# Asigna una unidad temporal y luego asigna la unidad especifica
if ($Global:Appdisk -notlike $Appletter) { 
    "En el IF de Appdisk"
    Set-Partition -DriveLetter $Global:Appdisk -NewDriveLetter $($Appletter)
    # Set-Partition -DriveLetter 'Y' -NewDriveLetter $Appletter
}
if ($Global:pagedisk -notlike $Pageletter) {
# Elimina la configuración de paginación en caso sea administrado por el O.S.
	$pagefiles = Gwmi win32_pagefilesetting 
	foreach ($pagefile in $pagefiles) {
		$pagefile.Delete()
	}
	Restart-Computer -Force
<#
	GetVolumes -SystemLabels $SystemLabels	
	
    Set-Partition -DriveLetter $Global:pagedisk  -NewDriveLetter $($Pageletter)
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{name = "P:\pagefile.sys"; InitialSize = 0; MaximumSize = 0 } -EnableAllPrivileges  | Out-Null
#>	
}


<## Configura la paginación de forma dinámica
if ($Global:Pagedisk -like $Pageletter) {
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{name = "P:\pagefile.sys"; InitialSize = 0; MaximumSize = 0 } -EnableAllPrivileges  | Out-Null
}
#>
Write-Output "Resultado:"
GetVolumes -SystemLabels $SystemLabels
Write-Output    $Global:Pagedisk
Write-Output    $Global:Appdisk  
#>



