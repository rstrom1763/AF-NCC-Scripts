Add-Type -AssemblyName PresentationCore,PresentationFramework

$ButtonType = [System.Windows.MessageBoxButton]::OK

$MessageboxTitle = "Reboot Required"
$MessageboxBody = "Your system will reboot in 5 minutes.`nSave your data now."

$MessageIcon = [System.Windows.MessageBoxImage]::Warning

#[System.Windows.MessageBox]::Show($MessageboxBody,$MessageboxTitle,$ButtonType,$MessageIcon)

$Result = [System.Windows.MessageBox]::Show($MessageboxBody,$MessageboxTitle,$ButtonType,$MessageIcon)

Switch ($Result) {
    "Yes" {Write-host "Nice" -ForegroundColor Green}
    "No"  {Write-Host "Really?" -ForegroundColor Red}
    "Cancel" {Write-Host "Too bad." -ForegroundColor Cyan}
    }

Start-Sleep -Seconds 10
Write-host "More stuff" -ForegroundColor White