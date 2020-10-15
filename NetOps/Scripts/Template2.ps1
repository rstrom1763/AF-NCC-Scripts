$Plugin = "wsus"

$TimeToWait = 2

$LogFile = "C:\LOGS\SCRIPTLOG.TXT"
$Date = Get-Date

if (!(Test-Path "C:\LOGS"))
{
    New-Item -Path "C:\LOGS" -ItemType "directory" -force
}

if (Test-Path $LogFile)
{
    Remove-Item $LogFile -Force
}

New-Item $LogFile -ItemType file
"Script started for $Plugin install on $Date" | Add-Content $LogFile

$computers = Get-Content "\\131.61.226.98\McConnell_Public\Patching\Plugins\$Plugin\Single.txt"
ForEach($computer in $computers)
{
    #$computer = $computer + ".area52.afnoapps.usaf.mil"
    if (!(Test-Connection $computer -count 1 -ErrorAction SilentlyContinue))
    {
        Write-Host "$computer not connected" -foreground red
        "$computer not connected ($Plugin install)" | Add-Content $LogFile
    }

    else
    {
        if (!(Test-Path "\\$computer\c$\installfiles\Deploy"))
        {
            New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force
        }

        Remove-Item "\\$computer\c$\installfiles\Deploy\*" -Recurse -Force

        psexec -s \\$computer powershell.exe Enable-PSRemoting -force

        Start-Sleep $TimeToWait
        Copy-Item \\131.61.226.98\McConnell_Public\Patching\Plugins\$Plugin\Deploy\* "\\$computer\C$\installfiles\Deploy\" -Recurse -Force -ErrorAction SilentlyContinue

        start-sleep -seconds $TimeToWait
        Invoke-Command -ComputerName $computer -ScriptBlock {C:\installfiles\Deploy\install.ps1} -AsJob

<#

        $file = "c$\installfiles\Deploy\install.ps1"
        $process = [wmiclass]"\\$computer\root\cimv2:win32_process"
        $remoteprocess = $process.create("powershell.exe -executionpolicy bypass -file c:\installfiles\Deploy\install.ps1")
        $RemoteprocessID = $remoteprocess.processID


        If($RemoteProcess.returnvalue -eq "0")
        {
            Write-Host "Process $RemoteProcessID has been started on $computer" -foregroundcolor green
            "$computer process started ($Plugin install)"| Add-Content $LogFile
        }

        If($remoteProcess.Returnvalue -ne "0")
        {
            $returnvalue = $RemoteProcess.returnvalue
            write-host "Remote Process not started on $computer, returnvalue is $returnvalue" -foregroundcolor red
            "$computer process not started ($Plugin install)"| Add-Content $LogFile
        }
#>
    }
}