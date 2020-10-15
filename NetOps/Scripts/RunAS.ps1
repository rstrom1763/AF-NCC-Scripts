$computers = Get-Content "C:\Strom\RunAs.txt"

    while (1 -eq 1) {
        foreach ($computer in $Computers) {

            if (Test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -Quiet) {
                Write-Host "Computer - $Computer" -ForegroundColor Cyan

                $OldValue = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser").ConsentPromptBehaviorUser
                }
                Write-Host "Old Value: $OldValue" -ForegroundColor Yellow

                if($OldValue -eq "3") {
                    Write-Host "$Computer is already hit.`n" -ForegroundColor Green
                }

                else {
                Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value "3" 
                }

                $NewValue = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser").ConsentPromptBehaviorUser 
                }

                Write-Host "New Value: $NewValue`n" -ForegroundColor Green
            }
        }

        else {
            Write-Host "$Computer is offline`n" -ForegroundColor Red
        }
        $Time = Get-Date -Format G
        Write-Host $Time
    }

    sleep 60
}

#(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser").ConsentPromptBehaviorUser