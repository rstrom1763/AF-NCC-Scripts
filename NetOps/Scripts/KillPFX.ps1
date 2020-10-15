$Patch = "\\52prpr-fs-001\Patching\Plugins\RemovePFX\Deploy\install.ps1"
$FilePath = "C:\Users\1086335782C\Desktop"
$InFile = "dns.txt"
$OutFile = "Good.TXT"

$Computers = Get-Content "$FilePath\$InFile"
$Success = "$FilePath\$OutFile"

# Create Log file and folder
if (!(Test-Path "$Success")) {
    New-Item -Path "$Success" -ItemType "file" -force
} else {
    Remove-Item $Success -Force
}

$GoodFile = $computers | Invoke-Ping -Quiet
$GoodFile >> $Success


    Get-ChildItem C:\ -Include *.p12, *.pfx -Exclude "preflight.p12", "gazette.pfx", "trustedps.pfx" -Recurse | foreach ($_) {
        Write-Host $env:Computername $_.FullName
        Remove-Item $_.fullname -Force
    }