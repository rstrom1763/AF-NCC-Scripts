<#
This PowerShell script will search a location for what may be PII information. It is not perfect.
The searcher will need to go through the results to see what is actually PII and what is not.
For example, this script will find files that have the word 'Card' or streams of numbers that start
with 4, 5, or 6 and have 16 numbers. I have commented out Pattern0 because it will appear on almost
any letter, and Pattern7 because it was incorporated into Pattern6.
#>

$SearchPath = "C:\Transfer\PSScripts"  #  <----- Put the drive path to search here
$OutputPath = "C:\Users\1086335782C\Desktop" # <--------This is where you put the directory to the Results.txt file
$OutputFile = "Results.txt"
$ComputerName = "PRPR-FS-007V"   # < --------- Put the name of the searched server here (for reference)

$DestinationFile = "$OutputPath\$OutputFile"
$DrivePath = "X:"

$Pattern0 = "CC[:| ]"
$Pattern1 = "[0-9]{3}[-| ][0-9]{2}[-| ][0-9]{4}"
$Pattern2 = "[5-7]{1}[0-9]{15}"
$Pattern3 = "[4-6][0-9]{3}[-| ][0-9]{4}[-| ][0-9]{4}[-| ][0-9]{4}"
$Pattern4 = "Card[ Number| No| No.| #][:| ]"
$Pattern5 = "Maiden Name[:| ]"
$Pattern6 = "SS[A|]N[:| ]"
$Pattern7 = "SSAN[:| ]"
$Pattern8 = "DOB[:| ]"
$Pattern9 = "Card[:| ]"

$Exclude1 = ("*.exe", "*.dll", "*.zip", "*.ps1", "*.pdf", "*.pst", "*.ost")

if (!(Test-Path -Path "X:\")) {
    New-PSDrive -Name "X" -PSProvider FileSystem $SearchPath
}

if (!(Test-Path "$DestinationFile")) {
    New-Item -Path "$DestinationFile" -ItemType "file" -force
} else {
    Clear-Content -Path $DestinationFile
}

Add-Content -Value "$ComputerName"  -Path $DestinationFile

#Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern0 | Out-File $DestinationFile -Encoding ascii -Append 
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern1 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern2 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern3 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern4 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern5 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern6 | Out-File $DestinationFile -Encoding ascii -Append
#Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern7 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern8 | Out-File $DestinationFile -Encoding ascii -Append
Get-ChildItem $DrivePath -Recurse -Exclude $Exclude1 | Select-String $Pattern9 | Out-File $DestinationFile -Encoding ascii -Append

(Get-Content $DestinationFile) | ? {$_.trim() -ne ""} | Set-Content $DestinationFile

Remove-PSDrive -Name "X"