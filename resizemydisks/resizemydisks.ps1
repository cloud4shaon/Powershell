function test123{
($rmvms=Get-AzurermVM -status) > 0
$vmlistFile = "$PSScriptRoot\vmlist.txt"  
$vmlist = Get-Content $vmlistFile
ForEach($VM in $vmlist)	
{
foreach($vmobj in $rmvms)
{
if($vmobj.name -eq $VM) {
$rg= $vmobj.resourcegroupname
Write-Host "Scanning OS and Data Disks on VM..." $vmobj.name 
$VMState = $VMobj | Get-AzureRmVm | Get-AzureRmVm -Status | 
select Name, @{n="Status"; e={$_.Statuses[1].DisplayStatus}}
if ($VMState.Status -eq "VM running") {
Write-Warning "VM is currently running. Stop the VM and try again"                      
}
else
{
##resizing OS DISK
$osdisksize = $vmobj.StorageProfile[0].OsDisk.DiskSizeGB
Write-Information "OS Disk Size = " $osdisksize
if ($osdisksize -lt 1023)
{
$vmobj.StorageProfile[0].OsDisk.DiskSizeGB=1024
Update-AzureRmVM -ResourceGroupName $rg -VM $vmobj -Verbose
}
else
{
Write-Warning " OS Disk Size is already 1 TB... Aborting"
}
##resizing Data DISK
$count = $vmobj.storageprofile[0].datadisks.count
if ($count -gt 0)
{
$count--
for ($dd=0; $dd -le $count; $dd++)
{
$diskname=$vmobj.storageprofile[0].datadisks[$dd] | select Name, @{n="diskname"; e={$_.Name}}
$disksize=$vmobj.storageprofile[0].datadisks[$dd] | select Name, @{n="sizeinGB"; e={$_.DiskSizeGB}}
##code to extend the size if it's less than 1024 GB
Write-Verbose "Scanning Data Disks...."
Write-Host "Checking Data Disk " $diskname.diskname
if ($disksize.sizeinGB -lt 1023)
{
Write-Host "Current Size of" $diskname.diskname "is" $disksize.sizeinGB "GB"
Write-Host "Extending" $diskname.diskname 
$vmobj.StorageProfile[0].datadisks[$dd].DiskSizeGB = 1024
Write-Host "Updating" $diskname.diskname "please wait" 
Update-AzureRmVM -ResourceGroupName $rg -VM $vmobj -Verbose
}
else
{
write-host "Disk Size is already 1 TB... Aborting"
}
}}}}}}}