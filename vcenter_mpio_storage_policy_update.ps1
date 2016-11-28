## Update all VMHosts in a vCenter Datacenter
## Nick Shores DSA - 5-18-2015

##Check for PowerCLI
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
  try {
    Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
  }
  catch {
    Write-Host "Please install VMware PowerCLI"
    Return
  }
}

## Get VCMS server address
if ($args[0] -ne $null) {
  $vcms_ip = $args[0]
}
else {
  $vcms_ip = Read-Host "Please enter vCenter Server hostname or IP"
}

## Connect to VCMS and get list of hosts
try {
  Connect-VIServer -Server $vcms_ip
  $Allhosts = Get-VMHost -ErrorAction Stop
}
catch {
  Write-Host "Could not connect to vCenter (" $vcms_ip ") and get hosts" $?
  Return
}


## Update Multi Pathing Policy on each host
ForEach ($VMHost in $AllHosts){
 try {
    $esxcli = Get-EsxCli -VMhost $vmhost -ErrorAction Stop
  }
  catch {
    Write-Host "Could not open EsxCli session. Could be an ESX 4.x host."
    Continue
  }

write-host "Setting MPIO Settings on $VMHost.name"
    get-vmhost $VMHost | Get-ScsiLun -LunType disk | Where { $_.MultipathPolicy -notlike "RoundRobin"} | Set-ScsiLun -MultipathPolicy "roundrobin"
    
foreach ($lun in Get-ScsiLun -VmHost $vmhost | ? {$_.Vendor -eq "EQLOGIC" }) { ##Find Equallogic Volumes Only
      Write-Host "Setting Roundbin PSP Policy for volume" $lun.CanonicalName
          $esxcli.storage.nmp.psp.roundrobin.deviceconfig.set(262144, $null, $lun.CanonicalName, 0, "iops", $null) 
    }

    }

write-host "Yay Finished!"


