 ##create empty array
$finaloutput = @()

#Get all VM's, then find VM's that are running Server 2012. Store the name and move on
$vms = get-vm | get-vmguest| where-object {$_.osfullname -eq "Microsoft Windows Server 2012 (64-bit)"} | select vmname,osfullname

#Loop for each vm that we found that will look up the nic type. Stores the name of the VM, and the Nic type in a array. 
foreach ($vm in $vms)

{ 
#create a new empty object to store our custom properties in 
$newobject = new-object system.object


$nic = Get-NetworkAdapter $vm.vmname | select type

$newobject | add-member -type NoteProperty -name Name -value $vm.vmname
$newobject | add-member -type NoteProperty -name Nic -value $nic.type
$newobject | add-member -type NoteProperty -name os -value $vm.osfullname
$finaloutput += $newobject

}

#show me vm's not that are not using vmxnet3
$finaloutput | where-object {$_.Nic -ne "Vmxnet3"}

