$computers = Get-Content "C:\Users\1086335782C\Desktop\runas.txt"
$SearchSoftware = "Java"

ForEach ($computer in $computers) {
    Get-InstalledSoftware $computer | Select-String $SearchSoftware
}
