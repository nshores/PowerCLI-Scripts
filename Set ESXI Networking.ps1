##Script for setting up networking/ntp/iscsi on ESXI5.5 or above host
##Script Does NTP,Networking,ISCSI, and Iscsi Config"
## Originally created for Rio Hondo Community College VDI Install
## Nick Shores - DSA - 5-19-16


function Set-VMHostiSCSIBinding {
<#
 .SYNOPSIS
 Function to set the iSCSI Binding of a VMHost.

 .DESCRIPTION
 Function to set the iSCSI Binding of a VMHost.

 .PARAMETER VMHost
 VMHost to configure iSCSI Binding for.

.PARAMETER HBA
 HBA to use for iSCSI

.PARAMETER VMKernel
 VMKernel to bind to

.PARAMETER Rescan
 Perform an HBA and VMFS rescan following the changes

.INPUTS
 String.
 System.Management.Automation.PSObject.

.OUTPUTS
 None.

.EXAMPLE
 PS> Set-VMHostiSCSIBinding -HBA "vmhba32" -VMKernel "vmk1" -VMHost ESXi01 -Rescan

 .EXAMPLE
 PS> Get-VMHost ESXi01,ESXi02 | Set-VMHostiSCSIBinding -HBA "vmhba32" -VMKernel "vmk1"
#>
[CmdletBinding()]

Param
 (

[parameter(Mandatory=$true,ValueFromPipeline=$true)]
 [ValidateNotNullOrEmpty()]
 [PSObject[]]$VMHost,

[parameter(Mandatory=$true,ValueFromPipeline=$false)]
 [ValidateNotNullOrEmpty()]
 [String]$HBA,

[parameter(Mandatory=$true,ValueFromPipeline=$false)]
 [ValidateNotNullOrEmpty()]
 [String]$VMKernel,

[parameter(Mandatory=$false,ValueFromPipeline=$false)]
 [Switch]$Rescan
 )

begin {

}

 process {

 foreach ($ESXiHost in $VMHost){

try {

if ($ESXiHost.GetType().Name -eq "string"){

 try {
 $ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
 }
 catch [Exception]{
 Write-Warning "VMHost $ESXiHost does not exist"
 }
 }

 elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]){
 Write-Warning "You did not pass a string or a VMHost object"
 Return
 }

 # --- Check for the iSCSI HBA
 try {

$iSCSIHBA = $ESXiHost | Get-VMHostHba -Device $HBA -Type iSCSI
 }
 catch [Exception]{

throw "Specified iSCSI HBA does not exist"
 }

# --- Check for the VMKernel
 try {

$VMKernelPort = $ESXiHost | Get-VMHostNetworkAdapter -Name $VMKernel -VMKernel
 }
 catch [Exception]{

throw "Specified VMKernel does not exist"
 }

# --- Set the iSCSI Binding via ESXCli
 Write-Verbose "Setting iSCSI Binding for $ESXiHost"
 $ESXCli = Get-EsxCli -VMHost $ESXiHost

$ESXCli.iscsi.networkportal.add($iSCSIHBA.Device, $false, $VMKernel)

Write-Verbose "Successfully set iSCSI Binding for $ESXiHost"

# --- Rescan HBA and VMFS if requested
 if ($PSBoundParameters.ContainsKey('Rescan')){

Write-Verbose "Rescanning HBAs and VMFS for $ESXiHost"
 $ESXiHost | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
 }
 }
 catch [Exception]{

 throw "Unable to set iSCSI Binding config"
 }
 }
 }
 end {

 }
}

##Enviroment Variables (Add more here)
$iscsitarget = "10.10.10.110"
$VMHost = “10.9.250.70“
$VMNetwork1Nics=“vmnic1“,“vmnic5“
$VMNetwork2Nics=“vmnic6“,“vmnic7“,“vmnic10“,“vmnic11“
$iscsi1 = “10.10.10.71“
$iscsi1subnet = “255.255.255.0“
$iscsi2 = “10.10.10.72“
$iscsi2subnet = “255.255.255.0“
$VMotionIP = “10.10.20.70“
$VMotionSubnet = “255.255.255.0“
$VMNetwork3Nics=“vmnic2“,“vmnic3“,“vmnic8“,“vmnic9“


## Get VCMS server address
if ($args[0] -ne $null) {
  $vcms_ip = $args[0]
}
else {
  $vcms_ip = Read-Host "Please enter vCenter/ESXI Server hostname or IP"
}

## Connect to VCMS 
  Connect-VIServer -Server $vcms_ip





##--Setup NTP--##

write-host "Setting up NTP"

Add-VMHostNtpServer -VMHost $VMHost -NtpServer ‘pool.ntp.org‘

Get-VmHostService -VMHost $VMHost |Where-Object {$_.key-eq “ntpd“} |Start-VMHostService

Get-VmhostFirewallException -VMHost $VMHost -Name “NTP Client“ |Set-VMHostFirewallException -enabled:$true

##--Setup NTP--##

write-host "Setting up Networking"
##Networking 

##Setup Management Port Group

New-VirtualPortGroup -VirtualSwitch "Vswitch0"  -Name "Management Port Group"

##Setup iScsi Network

New-VirtualSwitch -VMHost $VMHost -Name “vSwitch1“ -Nic $VMNetwork1Nics

New-VMHostNetworkAdapter -PortGroup “iscsi1“ -VirtualSwitch “vSwitch1“ -IP $iscsi1 -SubnetMask $iscsi1subnet -VMotionEnabled:$false

New-VMHostNetworkAdapter -PortGroup “iscsi2“ -VirtualSwitch “vSwitch1“ -IP $iscsi2 -SubnetMask $iscsi2subnet -VMotionEnabled:$false

write-host "Setting NIC Team order for iScsi VMK"
## Change NIC Team order for Iscsi Adapters
Get-VirtualPortGroup -VMHost $VMhost -VirtualSwitch vswitch1 -Name iscsi1 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1 -MakeNicUnused vmnic5
Get-VirtualPortGroup -VMHost $VMhost -VirtualSwitch vswitch1 -Name iscsi2 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic5 -MakeNicUnused vmnic1

##setup Vmotion Nework

New-VirtualSwitch -VMHost $VMHost -Name “vSwitch2“ -Nic $VMNetwork2Nics

New-VMHostNetworkAdapter -PortGroup “VMotion“ -VirtualSwitch “vSwitch2“ -IP $VMotionIP -SubnetMask $VMotionSubnet -VMotionEnabled:$true

## Setup Production Network 

New-VirtualSwitch -VMHost $VMHost -Name “vSwitch3“ -Nic $VMNetwork3Nics
New-VirtualPortGroup -VirtualSwitch "Vswitch3"  -Name "Production"

# Enable Software iSCSI Adapter on each host

Write-Host "Enabling Software iSCSI Adapter on $VMhost ..."

Get-VMHostStorage -VMHost $VMhost | Set-VMHostStorage -SoftwareIScsiEnabled $True


## Enable ISCSI VMK Port Binding on vmk1 and 2
write-host "Enabling ISCSI Port Binding"
## find hba
$hba = Get-VMHostHba -VMHost $vmhost -Type iscsi | %{$_.Device}
Set-VMHostiSCSIBinding -HBA $hba -VMKernel "vmk2" -vmhost $VMhost -Rescan 
Set-VMHostiSCSIBinding -HBA $hba -VMKernel "vmk1" -vmhost $VMhost -Rescan


## set ISCSI Target
write-host "Setting Iscsi Target" 
New-IScsiHbaTarget -IScsiHba $hba -Address $iscsitarget -ChapName iscsi -ChapPassword iscsi -ChapType Preferred

write-host "Done!"
