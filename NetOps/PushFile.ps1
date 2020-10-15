# For the line below, replace the location in the quotes with a csv of computers, preferrably by IP

$FilePath = "C:\Transfer\PSScripts"
$FileList = "test.txt"

$Source = "\\prpr-fs-111v\mafb$\McConnell_Public\Patching\Plugins\VPN-Connectoid\*.*"
#$Destination = "c$\Users\Default\Desktop"

$computers = Get-Content "$FilePath\$FileList"

ForEach ($computer in $computers) {
    #Invoke-Command -Computername $computer -AsJob -ScriptBlock {
        Copy-Item $Source \\$computer\c$\Users\Public\Desktop -Recurse -Force
    #}
}