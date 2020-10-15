# For the line below, replace the location in the quotes with a csv of computers, preferrably by IP
$InFile = "RequiresPush.txt"
$FilePath = "C:\Transfer\PSScripts"

$computers = Get-Content "$FilePath\$InFile"

ForEach ($computer in $computers) {
    Invoke-Command -Computername $computer -AsJob -ScriptBlock {

        Get-ChildItem C:\ -Include *.p12, *.pfx -Exclude "preflight.p12", "gazette.pfx", "trustedps.pfx", "AFAS1.af.mil.pfx", "mrs_hv.pfx" -Recurse | foreach ($_) {
            Write-Host $env:Computername + $_.FullName
            Remove-Item $_.fullname -Force
        }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        (New-Object -ComObject Shell.Application).NameSpace(0x0a).Items() | Select-Object Name.Size.Path
    }
}