$FilePath = "C:\Transfer\PSScripts"
$InFile = "RmvUser.txt"

$Users = Get-Content "$FilePath\$InFile"


ForEach ($user in $Users) {
        Write-Host $user
        Remove-ADUser -Identity $user -Credential 1086335782.C.ADW@mil
}
