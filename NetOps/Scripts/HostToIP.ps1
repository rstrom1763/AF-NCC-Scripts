$Filepath = "C:\Transfer\PSScripts"
$InFile = "Good1.txt"
$OutFile = "Good.txt"
$Success = "$Filepath\$OutFile"

if (!(Test-Path "$Success")) {
    New-Item -Path "$Success" -ItemType "file" -force
} 
else {
    Remove-Item $Success -Force
}

function Get-HostToIP($hostname) {
    $result = [system.net.dns]::GetHostByName($hostname)
    $result.AddressList | ForEach-Object {$_.IPAddressToString}
}

Get-Content "$Filepath\$InFile" | ForEach-Object {(Get-HostToIP($_)) >> $Filepath\$OutFile} -ErrorAction SilentlyContinue
