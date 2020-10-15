$RegistryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

Test-Path $RegistryKey
if ($registrykey) {
	cd $RegistryKey 

	Set-ItemProperty -Path $registrykey -Name FeatureSettingsOverride -Value 0
	Set-ItemProperty -Path $registrykey -Name FeatureSettingsOverrideMask -Value 3

	Get-ItemProperty -Path $RegistryKey -Name FeatureSettingsOverride
	Get-ItemProperty -Path $RegistryKey -Name FeatureSettingsOverrideMask
} else {
    write-host "Registry key does not exist"
}