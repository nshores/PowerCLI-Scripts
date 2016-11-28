param(
 [string] $location=".",
 [array] $vcenters)
 
filter Get-FolderPath {
    $_ | % {
        $row = "" | select Name, Path
        $row.Name = $_.Name
        $current = $_.folder
        $path = ""
        do {
            $parent = $current
            if($parent.Name -ne "vm"){$path = $parent.Name + "\" + $path}
            $current = $current.Parent
        } while ($current.Parent -ne $null)
        $row.Path = $path
        $row
    }
}

function get-vCenterDetails
{
 param($vcenters)
 
 $allvmdetails=@()
 $vcs = Connect-VIServer $vcenters
 foreach ($vc in $vcs)
 {
  $DCs=Get-Datacenter -server $vc|Sort-Object name
  foreach ($DC in $DCs)
  {
   Write-Host "Getting DC $DC"
   Get-Cluster -Location $DC|sort-object name| %{
    $cluster = $_
    
    Write-Host "Getting cluster $cluster"
    $vmhosts=Get-vmhost -Location $cluster|Sort-Object name
        
    write-host "Getting VM details..."
    $allvmdetails += $cluster | Get-VM|Sort-Object name|select @{n="vmname";e={$_.name}}, `
     @{n="Datacenter";e={$DC.name}}, `
     powerstate, `
     @{n="OS";e={$_.guest.OSFullName}}, `
     version, `
     @{n="Folder";e={($_|get-folderpath).path}}, `
     @{n="ToolsStatus";e={$_.guest.ExtensionData.ToolsStatus}}, `
     VMhost, `
     @{n="Cluster";e={$cluster.name}}, `
     NumCPU, `
     @{n="MemMB";e={$_.memorymb}}, `
     @{n="DiskGB";e={[Math]::Round((($_.HardDisks | Measure-Object -Property CapacityKB -Sum).Sum / 1MB),2)}}, `
     Notes
   }
  }
 }
 $allvmdetails
}

$date=get-date -Format yyyy.MM.dd
write-host "Getting Host and VM details: $(get-date)"
$vcenterdetails=get-vcenterdetails $vcenters
$vcenterdetails|export-csv -NoTypeInformation "$location\VMware_vmdetails_$date.csv"
write-host "Done: $(get-date)"

Disconnect-VIServer * -Confirm:$false -force

