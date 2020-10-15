#-------------------------------
# FIND EMPTY GROUPS
#-------------------------------

# Get empty AD Groups within a specific OU
$Groups = Get-ADGroup -Filter { Members -notlike "*" } -SearchBase "OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" `
 | Select-Object Name, GroupCategory, DistinguishedName

#-------------------------------
# REPORTING
#-------------------------------

# Export results to CSV
$Groups | Export-Csv "C:\Strom\New folder\EmptyGroups.csv" -NoTypeInformation