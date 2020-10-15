$computers = Get-Content "C:\Transfer\PSScripts\computers.txt"

ForEach ($computer in $computers)
{
    $computer = $computer + ".area52.afnoapps.usaf.mil"
    Write-Host $computer -ForegroundColor red
    Invoke-Command -ComputerName $computer -ScriptBlock {Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSComputerName | Format-Table -AutoSize }
}