C:\installfiles\Deploy\jre-x64.exe INSTALLCFG=C:\installfiles\Deploy\INSTALLER.CFG

$msiexecinstallargs64d = '/i "C:\installfiles\deploy\DBsignWebSigner_3.0.0.1.msi" /qn /norestart'
Start-Process msiexec.exe -Arg $msiexecinstallargs64d -Wait