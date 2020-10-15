#Sends a popup message to designated computer

function Message-Computer {

    Param([Parameter(Mandatory=$True)][String]$Computer,[String]$Message)

    Invoke-WmiMethod -Class Win32_Process -ComputerName $computer -Name Create -ArgumentList "C:\Windows\System32\msg.exe * $message"

}

#A1C Strom