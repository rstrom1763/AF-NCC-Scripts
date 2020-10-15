$PatchServer = "\\PRPR-FS-007V\McConnell_Public\Patching\Plugins"
$Patch = "KB3183038\Deploy"
$arg2 = "/quiet"
$arg3 = "/norestart"

$Patch_x32 = "IE11-Windows6.1-KB3185319-x86.msu"
$Patch_x64 = "IE11-Windows6.1-KB3185319-x64.msu"

if ((Get-WmiObject -Class Win32_OperatingSystem -ea 0).OSArchitecture -eq "64-bit") {

    if (!(Get-HotFix -Id KB3185319)) {    
        Copy-Item   "$PatchServer\$Patch\$Patch_x64" C:\installfiles\Deploy
        wusa.exe /install "C:\installfiles\Deploy\$Patch_x64" $arg2 $arg3 
        Start-Sleep -Seconds 30
    }

} else {

    if (!(Get-HotFix -Id KB3185319)) {    
        Copy-Item   "$PatchServer\$Patch\$Patch_x32" C:\installfiles\Deploy
        wusa.exe /install "C:\installfiles\Deploy\$Patch_x32" $arg2 $arg3 
        Start-Sleep -Seconds 30
    }
}
