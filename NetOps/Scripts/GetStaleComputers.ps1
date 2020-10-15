$DaysInactive = 90
$TestFile = "C:\Strom\"
$time = (Get-Date).AddDays(-($DaysInactive))

Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -ResultPageSize 2000 -ResultSetSize $null `
        -Properties Name, OperatingSystem, SamAccountName, DistinguishedName | `
    Export-Csv $TestFile\StaleComps.csv -NoTypeInformation