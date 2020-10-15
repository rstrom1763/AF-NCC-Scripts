$computers = Get-Content "C:\Transfer\PSScripts\computers.txt"
$samAccountName = "1149227799N"

ForEach ($computer in $computers) {
    $tempPath1 = "\\" + $computer + "\C$\Users\" + $samAccountName + "\"
    $tempPath2 = "\\" + $computer + "\C$\Users\" + $samAccountName + "." + $domainNetBios + "\"
    if ((Test-Path $tempPath1) -or (Test-Path $tempPath2)) {
        Write-Output $computer >> C:\Transfer\PSScripts\35192200071545.txt
    }
}