#Creates a CSV of all of the security groups in specified OU, in order to find non-compliant groups.


$groupType = "Security Groups"

$groups = Get-ADGroup -SearchBase "OU=McConnell AFB $groupType,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=area52,DC=afnoapps,DC=usaf,DC=mil" -Filter '*' -Properties * |  #Collects computer info from AD
Select-Object cn,ManagedBy,members

foreach($group in $groups){

    $group.members = $group.members.Count
    
}


$groups | where members -ne 0 | Export-Csv "C:\Strom\$groupType.csv" -encoding ASCII -NoTypeInformation


#A1C Strom