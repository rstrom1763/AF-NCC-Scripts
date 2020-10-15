# Get date and time
$today = Get-Date -DisplayHint date
$time = Get-Date -Format t
Write-Host "Today is $today" -ForegroundColor "Red"

# Import Active-Directory Module
Import-Module ActiveDirectory
Write-Host "`t Active Directory Module Imported" -ForegroundColor "Green"

# Import Windows Update Module
Import-Module PSWindowsUpdate
Write-Host "`t Windows Update Module Imported" -ForegroundColor "Green"

# Set Colors
$host.PrivateData.ScriptPaneBackgroundColor = "#DDDDDDDD"
$host.PrivateData.ScriptPaneForegroundColor = "Black"
$host.PrivateData.ConsolePaneBackgroundColor = "Black"
$host.PrivateData.ConsolePaneTextBackgroundColor = "Black"
$host.PrivateData.ConsolePaneForegroundColor = "Yellow"

# Set Fonts
$host.PrivateData.FontName = "Lucida Console"
$host.PrivateData.FontSize = "8"

# Run personal scripts
Set-Location C:\Transfer\PSScripts

function prompt {
	$time = Get-Date -Format t
     "$time " + "$(Get-Location)>"
}

$psdir = "C:\Transfer\PSProfile\autoload"
Get-ChildItem "${psdir}\*.ps1" | %{.$_}

Write-Host "Custom PowerShell Environment is kicking it...." -ForegroundColor "Green"