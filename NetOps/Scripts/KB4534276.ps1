$computers = Get-Content "C:\Transfer\PSScripts\COMPUTERS.txt"
    
ForEach ($computer in $computers) {
    if (!(Test-Path "\\$computer\c$\installfiles\Deploy")) {
            New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force
    }

    Write-host "Starting install Windows KB4534276-1709 on $computer..."
    Copy-Item "\\prpr-fs-111v\MAFB$\MCCONNELL_PUBLIC\Patching\Plugins\KB4534276-1709" \\$computer\c$\installfiles\Deploy -Recurse -Force -ErrorAction SilentlyContinue
    wusa.exe /install "C:\installfiles\Deploy\windows10.0-kb4534276-x64.msu" /quiet
    #Start-Sleep -Seconds 10
}