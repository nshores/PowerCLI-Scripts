#Migrate ESXI Networking settings between hosts
#Nick Shores - 11/11/16
#tested on ESXI 6.0 and 5.5 
$ErrorActionPreference = 'continue'


#source host
$source = "esx6.int.yccesa.org"

#destination host
$destination = "esx7.int.yccesa.org"

#Gather Information
$vswitch = get-vmhost $source | get-virtualswitch
$pg = get-vmhost $source | Get-VirtualPortGroup 

#Examine and create new vSwitches
ForEach ($switch in $vswitch){

$MySwitchName = $switch.name
$MySwitchNic = $switch.nic

#create new vswitch
write-host "creating new vswitch - $MySwitchName"
new-virtualswitch -VMHost $destination -Name $MySwitchName -nic $MySwitchNic |out-null
}


#examine port groups

    foreach ($group in $pg){

    $PGName = $group.name
    $PGVLANID = $group.vlanid
    $vSwitchName = $group.VirtualSwitchName

    write-host "checking $PGNAME"

    #Check if PortGroup is for Virtual Machines 
    if ($group.port.type -notmatch "host") 
    {
    write-host "$PGName is a Virtual Machine Port Group"

    #check to see if it already exists
    $pgcheck = Get-VirtualPortGroup -VMHost $destination -Name $pgname
    if ($pgcheck.Name -ne "$pgname"){
    write-host "Creating $pgname"
    get-virtualswitch $destination -Name $vSwitchName | New-VirtualPortGroup -Name $PGname -VLanId $PGVLANID | out-null
    
    } 
  

    else {
    #port group is a vmk or empty port group
    write-host "$PGname is a VMK"
    $vmklookup = Get-VMHostNetworkAdapter -vmhost $source | where-object {$_.portgroupname -like "$pgname"} 
    #create new VMK -- Uncomment to use
    #new-VMHostNetworkAdapter -vmhost $destination -ip $vmklookup.ip -mtu $vmklookup.mtu -SubnetMask $vmklookup.SubnetMask -PortGroup $vmklookup.PortGroupName -VirtualSwitch $group.VirtualSwitchName
    }

  }
}


write-host finished 




