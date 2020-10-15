$computers = Import-Csv \\prpr-fs-007v\McConnell_Public\Patching\Plugins\Firefox\firefox.csv

ForEach($computer in $computers)
{
        New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force

        Copy-Item \\prpr-fs-007v\McConnell_Public\Patching\Plugins\Firefox\Deploy\* "\\$computer\C$\Windows\Temp" -Force

        $file = "C:\Windows\Temp\install.ps1"
	    $process = [wmiclass]"\\$computer\root\cimv2:win32_process"
	    $remoteprocess = $process.create("powershell.exe -executionpolicy bypass -file C:\Windows\Temp\install.ps1")
	    $RemoteprocessID = $remoteprocess.processID
	    If($RemoteProcess.returnvalue -eq "0")
            {
            	Write-Host "Process $RemoteProcessID has been started on $computer" -foregroundcolor green
            }
	    If($remoteProcess.Returnvalue -ne "0")
	    {
		    $returnvalue = $RemoteProcess.returnvalue
		    write-host "Remote Process not started on $computer, returnvalue is $returnvalue" -foregroundcolor red
	    }
        Start-Sleep -Seconds 60
}