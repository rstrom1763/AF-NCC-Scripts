#====================================================
# Remove .PFX and .P12 files from system
#====================================================
Get-ChildItem C:\ -Include *.p12, *.pfx -Exclude "preflight.p12", "gazette.pfx", "trustedps.pfx", "AFAS1.af.mil.pfx", "mrs_hv.pfx" -Recurse | foreach ($_) {
    Write-Host $env:Computername + $_.FullName
    Remove-Item $_.fullname -Force
}





Exit

Enter-PSSession $computer

Clear-RecycleBin  -Force
(New-Object -ComObject Shell.Application).NameSpace(0x0a).Items() | Select-Object Name.Size.Path


# $crap = "C:\Users\1180000140A\AppData\Local\Microsoft\Windows\INetCache\IE\WF1BGDCF\SMITH.JENSEN.M.1180000140.p12"

if (test-path  $crap) {
    remove-item -Path $crap -force
    write-host "Removed $crap"
}

test-path $crap

#Testing ------------------------------------------------------------------------------------------------

$computer = "PRPRL-461NW9"

Invoke-Command -Computername $computer -ScriptBlock {

    Get-ChildItem C:\ -Include *.p12, *.pfx -Exclude "preflight.p12", "gazette.pfx", "trustedps.pfx", "AFAS1.af.mil.pfx", "mrs_hv.pfx" -Recurse | foreach ($_) {
        Write-Host $env:Computername + $_.FullName
        Remove-Item $_.fullname -Force
    }

    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    (New-Object -ComObject Shell.Application).NameSpace(0x0a).Items() | Select-Object Name.Size.Path
}