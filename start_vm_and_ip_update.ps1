<# Rapid Recovery Post Failover Script - Script functions:
1. Start all VM's in envionrment
2. Detect valid VMTools startup on each VM
4. Answer VM questions
3. Set proper IP's on each VM based on CSV values


Example CSV Format -

Parent,MacAddress,IP,MASK,DNS1,DNS2,GATEWAY
NorthConf,00:50:56:99:66:d3,192.168.0.185,255.255.255.0,192.168.0.7,192.168.0.8,192.168.0.1

Tested against ESXI 6.5 and Windows Server 2008 R2/Windows 7. 
PowerCLI 6.5.1 needed.
Nick Shores
8-22-17
#>

#Insert your vCenter/ESXI host below
connect-viserver 10.1.101.18 
#Point this towards your CSV with the list of machine's and associated ip's
$iplist = import-csv C:\Users\nsadmin\Desktop\rgamactoname.csv
#Insert a local administrator account here
$guestuser = "localadmin"
#Insert a local administrator password here
$guestpassword = "localadminpassword"


#VM POWER ON AND VMWARE TOOLS WAIT

$vmguests = get-vm 

#Start Each VM - Answer VM question 
foreach ($vm in $vmguests) {
    write-host "Starting $vm"
    Start-VM -vm $vm | out-null
    sleep 2
    get-vm $vm | Get-VMQuestion | Set-VMQuestion -Option button.no -Confirm: $false 

}


#Wait for VM's to turn on 
sleep 10



do {
    $vmtools = get-vm | where-object {$_.PowerState -eq "PoweredOn"} |
        foreach-object {get-view $_.ID} | where-object {$_.guest.toolsstatus -match "Not"}
    $nametext = $vmtools.name
    if($vmtools -and $nametext) {
        clear-host
        write-host "Waiting for tools to start on the following machines:`n$nametext"
        sleep 10 
    }
    
} while($vmtools -and $nametext)



#Update IP's on VM's based on values in csv

foreach ($machine in $iplist){
    #Grab the interface name using WMI call
    $network = get-vm $machine.Parent | Invoke-VMScript -GuestUser $guestuser -GuestPassword $guestpassword -ScriptText "(gwmi Win32_NetworkAdapter -filter 'netconnectionid is not null').netconnectionid"
    $NetworkName = $Network.ScriptOutput
    $NetworkName = $NetworkName.Trim()
    $ip = "netsh interface ip set address ""$NetworkName"" static $($machine.ip) $($machine.mask) $($machine.gateway)"
    $dns1 = "netsh interface ip set dnsservers ""$NetworkName"" static $($machine.dns1)"
    $dns2 = "netsh interface ip add dnsservers ""$NetworkName"" $($machine.dns2)"  
    write-host "Setting Machine - $($machine.parent) to `n IP - $($machine.ip) `n DNS1 - $($machine.dns1) `n DNS2 -  $($machine.dns2)"

    #Set values 1 line at a time TODO - Figure out how to pass all lines using array?
    get-vm $machine.Parent | Invoke-VMScript -GuestUser $guestuser -GuestPassword $guestpassword -ScriptText $ip -ScriptType Bat
    get-vm $machine.Parent | Invoke-VMScript -GuestUser $guestuser -GuestPassword $guestpassword -ScriptText $dns1 -ScriptType Bat
    get-vm $machine.Parent | Invoke-VMScript -GuestUser $guestuser -GuestPassword $guestpassword -ScriptText $dns2 -ScriptType Bat
    }





