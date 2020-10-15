$computers = Get-Content "C:\Users\1086335782C\Desktop\RequiresPush.txt"
$FilePath = 'C:\installfiles\Popup\Informational.png'
$Source = "\\52prpr-fs-001\Patching\Popup\Popup_Picture\Informational.png"
ForEach ($computer in $computers)
{
    $computer = $computer #+ ".area52.afnoapps.usaf.mil"
    Write-Host $computer -ForegroundColor red
    #Invoke-Command -ComputerName $computer -ScriptBlock {Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSComputerName | Format-Table -AutoSize }
    if (!(Test-Path $computer\$FilePath))
    {
        #Remove-Item $computer\c$\installfiles\Popup\Informational.png -Force
        #Start-Sleep -Seconds 2
        Copy-Item $Source \\$computer\c$\installfiles\Popup\Informational.png -Force -ErrorAction SilentlyContinue
        Write-Host "$computer Completed `n"
    }
}