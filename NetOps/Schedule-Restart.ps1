# get computerlist from active directory
$targetComputerList = Get-ADComputer -SearchBase "OU=McConnell AFB Computers,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" -Filter * -Properties Name, LastLogonDate | sort -Descending LastLogonDate | select -ExpandProperty Name

$exemptComputersList = Get-ADGroupMember "###################" | Select -ExpandProperty Name

#$exemptComputersList = @("prprl-######","prprl-######","prprl-######","prprl-######")

$computerlist = Compare-Object $exemptComputersList $targetComputerList | Select -ExpandProperty InputObject

Write-Host "Target list = $($targetComputerList.count)"
Write-Host "Exempt list = $($exemptComputersList.count)"
Write-Host "Final list = $($computerlist.count)"


# loop through the list of computers
foreach ($computername in $computerlist)
{
    # code to execute remotely on device
    $scriptblock =
    {
        # checks to see if schedule already exists on remote device
        try
        {
            Get-ScheduledTask -TaskName "* - McConnell AFB Computer Scheduled Restart" #| Unregister-ScheduledTask -Confirm:$false
	        #$scheduleExists = Get-ScheduledTask -TaskName "SCOO - McConnell AFB Computer Scheduled Restart" -ErrorAction Stop
        }
        catch
        {
	        $scheduleExists = $null
        }
        <#        
        # if schedule does not exists do the following
        if (!($scheduleExists))
        {
	        $timeofday = Get-Random -Maximum 3 -Minimum 1
	        # this is for night restarts
	        if ($timeofday -eq 1)
	        {
		        $hour = Get-Random -Maximum 12 -Minimum 10
		        $startime = "$hour`:00"
		        schtasks /create /RU SYSTEM /SC WEEKLY /D SAT /ST $startime /TR "shutdown.exe -r -t 360 -c 'Please save all your work. This system will reboot in 1 hour.'" /TN "CRC - McConnell AFB Computer Scheduled Restart"
	        }
	        # this is for morning restarts
	        else
	        {
	            $hour = Get-Random -Maximum 4 -Minimum 0
	            $startime = "0$hour`:00"
                schtasks /create /RU SYSTEM /SC WEEKLY /D SUN /ST $startime /TR "shutdown.exe -r -t 360 -c 'Please save all your work. This system will reboot in 1 hour.'" /TN "CRC - McConnell AFB Computer Scheduled Restart"
	        }
        }
        else
        {
	        # do nothing
        }
        #>
    }

    #check for connection
    $connection = Test-Connection $computername -Count 1 -Quiet

    # do if device is connected
    if ($connection)
    {
        # invoke command on remote computer
        Invoke-Command -ComputerName $computername -ScriptBlock $scriptblock
    }
    else
    {
        Write-Host "Could not connect to device: $computername"
    }
}