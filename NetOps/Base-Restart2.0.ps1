function Restart-Base {

    param(

        [Parameter(Mandatory = $True)]$computers,
        [int]$delay,
        $restartDelay,
        $message

    )
    if ($null -ne $delay) {
        
        Start-Sleep -Seconds $delay

    }
    $computers = Get-Content $computers
    $computers = $computers | Invoke-Ping -quiet

    $scriptblock = {

        param(
            $message,
            $restartDelay
        )

        Function Message-Popup {

            Param([Parameter(Mandatory = $True)][String]$Message)

            Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "C:\Windows\System32\msg.exe * $message"

        }

        Message-Popup -Message $message 
        Start-Sleep -Seconds $delay
        Restart-Computer -Force

    }

    foreach ($PC in $computers) {

        Invoke-Command -ComputerName $PC $scriptblock -ArgumentList $message, $restartDelay -AsJob

    }
}