#define variables
$myFolder = Get-Folder -Name "Templates"
$vmhost = "esxi05-08.motherlode.com"

#store all existing templates
$current_templates = foreach($vmhost in get-vmhost) {get-template -Location $vmhost | select name,@{n='VMHOST';e={$vmhost.name}},@{n='VMTX';e={$_.extensiondata.config.files.VmPathName}}}
 
#remove all templates from inventory
get-template | remove-template 

#register them back

foreach ($template in $current_templates){
New-Template -Name $template.name -TemplateFilePath $template.vmtx -Location $myFolder -VMHost $vmhost
}



