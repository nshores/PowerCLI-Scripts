$Export|  ForEach-Object 
{$_   |   New-MailboxExportRequest -FilePath "file://servername/pst/$($_.alias).pst"}


$exportpath = \\server\c$\location
$mailbox = get-mailbox

foreach ($user in $mailbox) {
new-mailboxexportrequest -mailbox $user.name -filepath "$exportpath + $user.name + .pst"

write-host "exporting $user.username"

}

