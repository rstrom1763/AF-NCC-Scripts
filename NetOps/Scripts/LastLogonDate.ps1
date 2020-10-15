$computers = Get-Content "C:\Users\1086335782C\Desktop\certs.txt"

ForEach ($computer in $computers) {
    Get-ADComputer -identity $computer -Properties * | sort lastlogondate | Format-Table name, lastlogondate -autosize
}