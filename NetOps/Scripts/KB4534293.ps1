$computers = Get-Content "C:\Transfer\PSScripts\1803.txt"
    
ForEach ($computer in $computers) {
    if (!(Test-Path "\\$computer\c$\installfiles\Deploy")) {
            New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force
    }

    Write-host "Starting 1803 install on $computer..."
    Copy-Item "\\prpr-fs-111v\mafb$\McConnell_Public\Patching\Plugins\KB4534293-1803" \\$computer\c$\installfiles\Deploy -Recurse -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath "wusa.exe" -ArgumentList "\\$computer\c$\installfiles\Deploy\KB4534293-1803\windows10.0-1803.msu /quiet"
}