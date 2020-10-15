$groupsToChange = Get-Content "Insert file path here.txt"
$groupToAdd = "UDG_McConnell_IAO"
$domain = "Area52.afnoapps.usaf.mil"

foreach($group in $groupsToChange){

    Set-DRAGroup -Domain $domain -Identifier "CN=$group,OU=McConnell AFB Security Groups,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" `
        -Properties @{ManagedBy="CN=$groupToAdd,OU=McConnell AFB Distribution Lists,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL"} -IgnoreCertificateErrors -Force

}

#A1C Strom