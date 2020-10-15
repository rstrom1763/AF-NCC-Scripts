$computers = Get-Content "C:\Users\1086335782C\Desktop\flash.txt"
$good1 = "C:\Users\1086335782C\Desktop\swaplist.txt"

if (Test-Path "$good1") {
    Remove-Item "$good1"
    New-Item -ItemType file -Path "$good1"
}

$good = $computers | Invoke-Ping -Quiet
$good >> $good1