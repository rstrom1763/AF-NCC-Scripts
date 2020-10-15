$FilePath = "C:\Transfer\PSScripts"
$Outfile = "StaleUsers.txt"

Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=McConnell AFB Users, OU=McConnell AFB, OU=AFCONUSWEST, OU=Bases, DC=AREA52, DC=AFNOAPPS, DC=USAF, DC=MIL" `
    -ResultPageSize 2000 -ResultSetSize $null | Select-Object SamAccountName, DistinguishedName >> "$FilePath\$Outfile"