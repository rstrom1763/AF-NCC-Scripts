$computer = "prprl-5034fy"
$file = "C:\installfiles\Deploy\install.ps1"
	$process = [wmiclass]"\\$computer\root\cimv2:win32_process"
	$remoteprocess = $process.create("powershell.exe -executionpolicy bypass -file C:\installfiles\Deploy\install.ps1")
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
