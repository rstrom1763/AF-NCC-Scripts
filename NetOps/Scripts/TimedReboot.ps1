$COMPUTERS = Get-Content "C:\Users\1086335782C\Desktop\list1.txt"

ForEach ($computer in $computers) {
    if (!(Test-Connection $computer -BufferSize 16 -Count 1 -Quiet)) {
        Write-Host "$computer not connected." -ForeGroundColor DarkRed
    }
    else {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("This computer is scheduled for shutdown",10,"Save Data",0x0)
        $wshell.Popup("30 seconds to shutdown",2,"Save it or it will be gone.",0x0)
        $xCmdString = (sleep 30)
        Invoke-Command $xCmdString
        Restart-Computer -ComputerName $computer -Force
    }
}