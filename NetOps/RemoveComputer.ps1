$FilePath = "C:\Transfer\PSScripts"
$InFile = "RmvComp.txt"

$Computers = Get-Content "$FilePath\$InFile"


ForEach ($Computer in $Computers) {
        Write-Host $Computer
        remove-DRAComputer -domain area52.afnoapps.usaf.mil -Identifier $Computer -Force
}
