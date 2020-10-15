$Path = "C:\Transfer\PSScripts"
$FileName = "computers.txt"

$computers = Get-Content "$Path\$FileName"

ForEach ($computer in $computers) {
    Write-host "Restarting $computer.`n"
    #Restart-Computer -ComputerName $computer -Force -ErrorAction SilentlyContinue
    Invoke-Command -ComputerName $computer -ScriptBlock { Start-Process "notepad.exe" }
}