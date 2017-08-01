#The EQL Powershell Extension is required - https://eqlsupport.dell.com/support/download_file.aspx?id=3336
#The Nimble Powershell Module is required  - https://infosight.nimblestorage.com/InfoSight/media/software/active/15/49/Nimble_PowerShell_ToolKit_1.0.0.zip
#Nick Shores 8-1-17

#Change paramaters below to match your enviornment  
$vcenter = 192.168.0.46
$vcenteruser = yourusername
$vcenterpass = your vcenter password
$EqlCred = Get-Credential
$NimbleCred = Get-Credential

#Import Modules
Import-Module -Name 'C:\Program Files\EqualLogic\bin\EqlPSTools.dll'
import-module -Name 'NimblePowerShellToolKit'

#Connect to depencies
connect-viserver -server $vcenter -User $vcenteruser -Password $vcenterpass
Connect-Eqlgroup -GroupAddress 192.168.0.81 -Credential $EqlCred
Connect-NSGroup -group 192.168.0.66 -credential $NimbleCred


#Get list of EQL Volumes to create 

write-host 'Getting EQL Volumes...'
$eqlvolume = Get-EqlVolume


$volumestats = $eqlvolume | select VolumeName,VolumeSize
write-host "$volumestats"

Write-Host "Creating $eqlvolume.count New Volumes - Continue? "
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



#On nimble, create each volume
#TODO - Figure out how to set chap / initator access
foreach ($volume in $eqlvolume) {
    new-nsvolume -name $volume.VolumeName -size $volume.VolumeSizeMB -multi_initiator $true
    }
    
Get-NSVolume | select name-size

write-host "Creating Datastores"

#Find nimble LUN's / create new datastores
$id = Get-ScsiLun -vmhost * | Get-ScsiLunPath | ? {($_.Sanid -like '*nimble*') -and ($_.State -eq 'Active')}
foreach ($lun in $id){
  $name = $lun.sanid -replace '.*?:(.+?)-.*','$1'  
  new-datastore -Name $name -path $lun.ScsiCanonicalName -vmhost * 
  }

  
#Rescan Hosts
Get-VMHostStorage -VMHost * -RescanAllHBA | Out-Null


write-host "Complete!"