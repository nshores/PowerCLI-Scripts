##Recreate Fairchild View Pools
## Run with View PowerCLI console on new connection server
## Tested against vMware View 6.0.2 Connection Server
## Nick Shores 1/29/16

$legacyvc = "view-cs-fmc1"
$newvc = "fmc-vdi-cs01"
$automated_pools_float = import-csv "automated_pools_float.csv"
$automated_pools = import-csv "automated_pools_dedicated.csv"
$dedicated_pools = import-csv "manual_pool_filter.csv"
$entitlement = import-csv "pool_user_entitlement.csv"

#Create  Automated Linked Clone Pools with floating users (SVInonpersistant)
#PS  get-pool | where {$_.pooltype -eq "SviNonPersistent"} |
#select pool_id,displayname,nameprefix,parentvmpath,parentvmsnapshotpath,vmfolder
#path,resourcepoolpath,datastorespecs,minimumcount,maximumcount | export-csv auto
#mated_pools_float.csv

#start-transcript

write-host "Generating Automated Pools (floating)"

foreach ($pool in $automated_pools_float) {
Get-ViewVC -serverName $newvc | Get-ComposerDomain -domain fairchildmed.home | Add-AutomaticLinkedCLonePool `
-pool_id $pool.pool_id `
-displayName "`""$pool.displayName"`"" `
-namePrefix "`""$pool.namePrefix"`"" `
-parentVMPath "`""$pool.parentVMPath"`"" `
-parentSnapshotPath "`""$pool.parentVMSnapshotPath"`"" `
-vmFolderPath "`""$pool.vmFolderPath"`"" `
-resourcePoolPath "`""$pool.resourcePoolPath"`"" `
-datastoreSpecs "`""$pool.datastoreSpecs"`"" `
-organizationalUnit "`""$pool.organizationalUnit"`"" `
-minimumCount "`""$pool.minimumCount"`"" `
-maximumCount "`""$pool.maximumCount"`"" `
-persistance nonpersistent `
-deletepolicy refreshonuse `
-isProvisioningEnabled:$true

write-host "Created $pool.displayname"

}

write-host "finished generating automated pools (floating)"

#Create  Automated Linked Clone Pools with dedicated users (SviPersistent)
#Code for generation of CSV file:
# get-pool | where {$_.pooltype -eq "SviPersistent"} | sel
#ect pool_id,displayname,nameprefix,parentvmpath,parentvmsnapshotpath,vmfolderpat
#h,resourcepoolpath,datastorespecs,minimumcount,maximumcount | export-csv automat
#ed_pools_dedicated.csv

write-host "Generating Automated Pools (dedicated)"

foreach ($pool in $automated_pools_float) {
Get-ViewVC -serverName $newvc | Get-ComposerDomain -domain fairchildmed.home | Add-AutomaticLinkedCLonePool `
-pool_id "`""$pool.pool_id"`"" `
-displayName "`""$pool.displayName"`"" `
-namePrefix "`""$pool.namePrefix"`"" `
-parentVMPath "`""$pool.parentVMPath"`"" `
-parentSnapshotPath "`""$pool.parentVMSnapshotPath"`"" `
-vmFolderPath "`""$pool.vmFolderPath"`"" `
-resourcePoolPath "`""$pool.resourcePoolPath"`"" `
-datastoreSpecs "`""$pool.datastoreSpecs"`"" `
-minimumCount "`""$pool.minimumCount"`"" `
-maximumCount "`""$pool.maximumCount"`"" `
-persistance persistent `
-deletepolicy default `
-isProvisioningEnabled:$false

write-host "Created $pool.displayname"

}

write-host "Finished Generating Automated Pools (dedicated)"

#Create manual Pools
# Code for generation of csv:
# get-desktopvm | select name,pool_id,isinpool | where-object {$_.isinpool -eq"true"} 

write-host "generating manual pools"

foreach ($pool in $dedicated_pools)
{
Get-ViewVC -serverName $newvc | Get-DesktopVM -name "`""$pool.name"`"" | Add-ManualPool -pool_id "`""$pool.pool_id"`""

write-host "Created $pool.name"

}

write-host "finished generating manual pools"

#Entitle Users

write-host "entitling users"

foreach ($user in $entitlement) {
Get-User -name "`""$user.displayName"`"" | Add-PoolEntitlement -pool_id "`""$user.pool_id"`""
}

write-host "finished"


#stop-transcript 