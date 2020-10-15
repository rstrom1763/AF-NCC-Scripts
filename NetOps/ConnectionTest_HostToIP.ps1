#####################################################
#      Ping Test                                    #
#####################################################

$FilePath    = "C:\Transfer\PSScripts"
$InFile      = "Win10.txt"
$TempFile    = "Good1.txt"
$OutFile     = "Good.txt"
$TempSuccess = "$FilePath\$TempFile"
$Success     = "$Filepath\$OutFile"

$computers   = Get-Content "$FilePath\$InFile"

# Create Log file and folder
if (!(Test-Path "$TempSuccess")) {
    New-Item -Path "$TempSuccess" -ItemType "file" -force
} 
else {
    Remove-Item $TempSuccess -Force
}

$TempFile = $computers | Invoke-Ping -Quiet
$TempFile >> $TempSuccess


#####################################################
#      Convert to IP Addresses                      #
#####################################################

# Create Log file and folder
if (!(Test-Path $Success)) {
    New-Item -Path $Success -ItemType "file" -force
} 
else {
    Remove-Item $Success -Force
}

function Get-HostToIP($hostname) {
    $result = [system.net.dns]::GetHostByName($hostname)
    $result.AddressList | ForEach-Object {$_.IPAddressToString}
}

Get-Content $TempSuccess | ForEach-Object {(Get-HostToIP($_)) >> $Success} -ErrorAction SilentlyContinue