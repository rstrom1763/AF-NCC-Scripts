$computers = Get-Content "C:\Users\1086335782C\Desktop\KB4056887.txt"
$watchfile = "C:\Users\1086335782C\Desktop\swaplist.txt"
$badboys = "C:\Users\1086335782C\Desktop\badboy.txt"
$goodcount = 0
$badcount = 0
$time = Get-Date -Format G

if (Test-Path $watchfile) {
    Remove-Item $watchfile
    New-Item $watchfile
}

if (Test-Path $badboys) {
    Remove-Item $badboys
    New-Item $badboys
}


ForEach ($computer in $computers) {
    if (!(Test-Connection $computer -Count 1 -Quiet)) {
        $computer | Add-Content "$badboys"
        $goodcount += 1
    }
    else {
         $computer | Add-Content "$watchfile"
         $badcount += 1
    }
}

Write-Host "There are $goodcount valid computers and $badcount disconnected ones." -ForegroundColor Green
Write-Host "Time Started: $time"
$time = Get-Date -Format G
Write-Host "Time completed: $time"