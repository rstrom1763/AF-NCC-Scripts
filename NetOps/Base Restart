cls 

#Relies on having the Invoke-Ping and Connection-Test files loaded into powershell before running. 
Connection-Test

#Computers references a text file that contains the list of computers that are to be affected by this script
$computers = Get-Content -path "C:\Strom\RequiresPush.txt"

Function Restart-Computers { #Function to be encapsulated into a job to be sent to the remote computers for restart

    Function Message-Popup{ #Function that handles creating the message pop-up for the user. 

        #The parameter Message is required. It is the message to be presented in the pop-up
        Param([Parameter(Mandatory=$True)][String]$Message)
        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "C:\Windows\System32\msg.exe * $message"

    }


    #Message contains the message that will be presented to the user
    $message = "This computer is scheduled to restart in approximately 10 minutes. Please save your work and have a wonderful day!"
    Message-Popup -Message $message #Creates the pop-up
    Start-Sleep -Seconds 600 #The number controls the number of seconds to wait before the computer will restart
    Restart-Computer -Force #Force restarts the computer

}

foreach($PC in $computers) { #Loop to distribute the restart job to all of the computers listed in computers
    
    #Invokes the Restart-Computers function on the remote machine as a job
    Invoke-Command -ComputerName $PC ${Function:Restart-Computers} -AsJob

}
