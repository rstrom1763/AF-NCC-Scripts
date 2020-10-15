$FilePath = "C:\Transfer\PSScripts"
$FileName = "computers.txt"

$computers = Get-Content "$FilePath\$FileName"

ForEach ($computer in $computers) {
    Write-host "Restarting $computer.`n"
    Restart-Computer -ComputerName $computer -Force -ErrorAction SilentlyContinue
}