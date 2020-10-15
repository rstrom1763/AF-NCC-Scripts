$computers = Get-Content "C:\Transfer\PSScripts\good.txt"
    
ForEach ($computer in $computers) {
    if (!(Test-Path "\\$computer\c$\installfiles\Deploy")) {
            New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force
    }

    Write-host "Starting 1809 install on $computer..."
    Copy-Item "\\prpr-fs-111v\mafb$\McConnell_Public\Patching\Plugins\KB4534273-1809" \\$computer\c$\installfiles\Deploy -Recurse -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath "wusa.exe" -ArgumentList "\\$computer\c$\installfiles\Deploy\KB4534273-1809\windows10.0-kb4534273-x64-1809.msu /quiet"
}