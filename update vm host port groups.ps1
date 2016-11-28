## Update some port groups on a host 
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



ForEach ($VMHost in $AllHosts){




write-host "Renaming Management Port Group on $VMHost.name"
Get-VirtualPortGroup -VMHost $VMhost -VirtualSwitch vswitch0 -Name Management | set-virtualportgroup -Name "VLAN 250" -vlanid 250

    
    }

write-host "Yay Finished!"


