<#

This script logs off a user on a remote computer.

Author: TSgt Daugherty, Matthew D. | Client Systems Technician | Sheppard AFB, TX

Last Edit: 20 May 2020

#>



function EnterComputerName {

    do {

        Clear-Host
        $ComputerName = Read-Host "`nEnter computer name"
        
    } until ($ComputerName)

    $ComputerName = $ComputerName.ToUpper()

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {

        $Session = New-PSSession -ComputerName $ComputerName -ErrorAction SilentlyContinue

        if ($Session) {LogoffUser}

        else {

            Clear-Host
            Write-Host "`nError: Could not establish PowerShell session with $ComputerName.`n" -ForegroundColor Red
            Pause
            EnterComputerName
        }
    }
    else {

        Clear-Host
        Write-Host "`nError: $ComputerName is not on the network.`n" -ForegroundColor Red
        Pause
        EnterComputerName
    }
}



function LogoffUser {

    Clear-Host

    Write-Output "`nSelect user to log off.`n"

    Pause

    Clear-Host

    $Quser = Invoke-Command -Session $Session -ScriptBlock {quser.exe 2>$null}

    $QuserObject = $Quser | ForEach-Object {$_ -replace '>' -replace '^\s' -replace '\s{2,}', ','} |
    ConvertFrom-Csv

    if ($null -ne $QuserObject) {

        $UserToLogoff = $QuserObject.USERNAME | Out-GridView -Title 'Select user to log off' -Outputmode Single

        $SessionName = ($QuserObject | Where-Object USERNAME -eq $UserToLogoff).SESSIONNAME

        Invoke-Command -Session $Session -ScriptBlock {logoff.exe $Using:SessionName}

        Write-Host "$UserToLogoff was logged off.`n" -ForegroundColor Green
    }
    else {Write-Host "`nThere is no user logged on.`n"}

    Pause
}



if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Write-Output "`nThis script logs off a user on a remote computer..`n"
Pause

EnterComputerName 