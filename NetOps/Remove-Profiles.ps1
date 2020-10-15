$FilePath = "C:\installfiles\Deploy"
$InFile = "RemoveProfiles.txt"

$Profiles = Get-Content "$FilePath\$InFile"

ForEach ($profile in $Profiles) {
    Write-Host "Removing profile $profile."
    Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath.split('\')[-1] -eq "$profile" } | Remove-CimInstance
}
