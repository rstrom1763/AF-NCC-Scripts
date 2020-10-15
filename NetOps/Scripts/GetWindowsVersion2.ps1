$InFile = "RequiresPush.txt"
$FilePath = "C:\Transfer\PSScripts"

$computers = Get-Content "C:\Transfer\PSScripts\RequiresPush.txt"

Foreach ($computer in $ComputerName) {
    $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
    $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
    Write-Host $computer, $ProductName, $Version
}