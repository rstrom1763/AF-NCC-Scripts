#====================================================
# Install HBSS
#====================================================
$PatchServer = "\\prpr-fs-007v\McConnell_Public\Patching\Plugins"

Copy $PatchServer\HBSS\Deploy\*.* C:\installfiles\Deploy\

cd "C:\Program Files\McAfee\Agent\x86"

cd "c:\Program Files (x86)\McAfee\Common Framework"

.\frminst.exe /forceuninstall

C:\installfiles\Deploy\FramePkg.exe /install=agent /forceinstall /S