Get-ADGroupMember -identity "22CES All" | select name | Export-Csv -Path C:\installfiles\Deploy\CES.csv -NoTypeInformation
