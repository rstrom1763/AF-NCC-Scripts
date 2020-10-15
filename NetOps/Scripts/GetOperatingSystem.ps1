$patch = "Java"
$computers = Get-Content "C:\Users\1086335782C\Desktop\Good1.txt"

ForEach($computer in $computers) {

    if (!(Test-Connection $computer -count 1 -ErrorAction SilentlyContinue)) {
        Write-Host "$computer not connected" -foreground red
    } else {
        #Get-WmiObject -computer $computer -Class win32_operatingsystem 
        #(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
        #Get-CimInstance Win32_OperatingSystem -ComputerName $computer |Select-Object PSComputerName,Caption,BuildNumber,Version
        Get-InstalledSoftware $computer | Select-String "$patch"
    }
}