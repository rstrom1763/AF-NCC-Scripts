$OutFile = "Computers.csv"
$FilePath = "C:\Transfer\PSScripts"

Get-ADComputer -Filter * -SearchBase "OU=McConnell AFB Computers, OU=McConnell AFB, OU=AFCONUSWEST, OU=Bases, DC=AREA52, DC=AFNOAPPS, DC=USAF, DC=MIL" `
    -ResultPageSize 0 -Properties CN, samaccountname, lastLogonTimeStamp | ` 
    Select CN, samaccountname, @{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} | `
    Export-CSV -NoType $FilePath\$OutFile
