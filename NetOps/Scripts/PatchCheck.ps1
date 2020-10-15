$InFile = "Win10.txt"
$FilePath = "C:\Transfer\PSScripts"

$computers = Get-Content "$FilePath\$InFile"

ForEach ($computer in $computers) {
    if (Test-Path "\\$computer\c$") {
        get-hotfix -ComputerName $computer -id KB4534273
    } else {
        Write-host "System $computer is not online" -ForegroundColor Cyan
    }
}