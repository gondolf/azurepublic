$SnapshotResourceGroupName ='arsgrsnapshots'
$DiskResourceGroupName ='arsgrautomation'
$vmName = "j6-prd-web3-ec" 
$location = 'East US'
$dataDiskName = $vmName + '_datadisk1'
$Snapshotdate = '20211214-203348'

$snapshots = Get-AzSnapshot -ResourceGroupName $SnapshotresourceGroupName -SnapshotName "*$($vmName)*" | 
Where-Object {($_.Name).Split('_')[-1] -contains $snapshotdate}

<#
$snapshots = Get-AzSnapshot -ResourceGroupName $SnapshotresourceGroupName -SnapshotName "*$($vmName)*" |
 Select-Object Name,TimeCreated, @{N='SourceId';E={$_.CreationData.SourceUniqueId}}, @{N='SourceResourceId';E={$_.CreationData.SourceResourceId}} | Sort-Object TimeCreated
#>







##   Deploy the new vm

##$dataDisks = Get-AzDisk -ResourceGroupName $DiskResourceGroupName -DiskName "$($vmName)*" 
$datadisks = Get-AzDisk | Where-Object {$_.ResourceGroupName -like $DiskResourceGroupName -and $_.Name -like "$($vmName)*"  -and $_.OsType -notlike 'Windows'} 

foreach ($disk in $disks){
    if ($disk.OsType) {$osdisk = $disk }
}

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_A2" ## Set the VM name and size
$vm = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id  ## Add the NIC
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType Standard_LRS `
    -DiskSizeInGB 128 -CreateOption Attach -Windows ## Add the OS disk
$vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $datadisk.Id -Lun 0





New-AzVM -ResourceGroupName $destinationResourceGroup -Location $location -VM $vm    ## Complete the VM

## Verify
$vmList = Get-AzVM -ResourceGroupName $destinationResourceGroup
$vmList.Name