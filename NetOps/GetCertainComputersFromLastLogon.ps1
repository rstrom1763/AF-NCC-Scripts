cls

$file = "C:\temp\5.5 Computers.txt"
$file2 = "C:\temp\ComputerLastLogonDate09-29-2020 10-06.csv"
$computers = Get-Content -Path $file
$lastlogon = Import-Csv $file2 
$savefile = "C:\Strom\New.csv"

foreach ($computer in $computers){

    $lastlogon | ForEach-Object { if ($_.cn -eq $computer){ Export-Csv -InputObject $_ -Path $savefile -Append;write-host $_ } }

}


#A1C Strom