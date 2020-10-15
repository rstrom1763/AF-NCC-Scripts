# Set up install
$Parameters = "/s"
Copy-Item \\prqens20vdm1\McConnell_Public\Patching\Plugins\Java\Deploy\jre-8u60-windows-i586.exe C:\installfiles\Deploy\

# If there is a previous version installed, stop the process
Write-Host ("Stopping all Java runtimes...`n")
if (Get-Process -Name java -ErrorAction SilentlyContinue) {Stop-Process -Name java -Force}
if (Get-Process -Name javaw -ErrorAction SilentlyContinue) {Stop-Process -Name javaw -Force}

# Uninstall all old versions of Java
Write-Host ("Uninstalling older versions of Java...`n")
$app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Java"}
foreach ($a in $app) {$a.Uninstall()}

# Install Java
Write-Host ("Installing latest version of Java...`n")
$InstallStatement = [System.Diagnostics.Process]::Start("C:\installfiles\Deploy\jre-8u60-windows-i586.exe", $Parameters)
$InstallStatement.WaitForExit()

Write-Host "Copying exemption list....`n"
if (Test-Path C:\Windows\SUN\JAVA\DEPLOYMENT\EXCEPTION.SITES.OLD) {
    Copy-Item \\prqens20vdm1\McConnell_Public\Patching\Plugins\JavaExempt\Deploy\EXCEPTION.SITES C:\Windows\SUN\JAVA\DEPLOYMENT\ -ErrorAction SilentlyContinue
} else {
    Copy-Item C:\Windows\SUN\JAVA\DEPLOYMENT\EXCEPTION.SITES C:\Windows\SUN\JAVA\DEPLOYMENT\EXCEPTION.SITES.OLD -ErrorAction SilentlyContinue
    Remove-Item C:\Windows\SUN\JAVA\DEPLOYMENT\EXCEPTION.SITES -ErrorAction SilentlyContinue
    Copy-Item \\prqens20vdm1\McConnell_Public\Patching\Plugins\JavaExempt\Deploy\EXCEPTION.SITES C:\Windows\SUN\JAVA\DEPLOYMENT\ -ErrorAction SilentlyContinue
}
