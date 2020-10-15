# Replace the location of your computer list here. It needs to be a text list.
$computers = Get-Content "Directory\ComputerNames.txt"

#Location and full name of the frame package. It should be the same one listed below.
$exe = "\\server\Files\Windows_FramePkg_EPO1_551-388.exe"

ForEach ($computer in $computers) {
    Invoke-Command -Computername $computer -AsJob -ScriptBlock {
        psexec.exe -s -d powershell.exe Enable-PSRemoting -force
        Start-Process $exe
    }
}