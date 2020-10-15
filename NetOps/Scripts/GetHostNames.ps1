$Desktop = "C:\Users\1086335782C\Desktop"
$INFile = "RequiresPush.txt"
$OUTFile = "certs.txt"

$computers = Get-Content "$Desktop\$INFile"

ForEach($computer in $computers) {
    $result = $null
    $currentEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $result = [System.Net.Dns]::GetHostEntry($computer)
    $ErrorActionPreference = $currentEAP

    if ($result) {
        $resultList += [string]$result.HostName
        $resultList += "`n"
    }
    else {
        $resultList += "IP - No HostName Found"
        $resultList += "`n"
    }
}

$resultList | Out-File $Desktop\HostList.txt
#$resultList