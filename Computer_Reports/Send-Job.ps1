#A1C Strom

Function Send-Job {

    Param(

        [Parameter(Mandatory = $True)]$computers, #text file with the computer names on individual lines. 
        [Parameter(Mandatory = $True)]$outputURI

    )

    if (!(Test-Path $computers)) {
        return (Write-Error "$computers does not exist. ")
    }

    Connection-Test -computers $computers -outfile "C:/temp/results.txt" #Relies on Invoke-Ping

    $computers = Get-Content "C:/temp/results.txt"
    
    Remove-Job -State Stopped, Failed

    $scriptblock = {
        
        param(
            $outputURI
            )

        function Get-UserSession {
            <#  
        .SYNOPSIS  
            Retrieves all user sessions from local or remote computers(s)

        .DESCRIPTION
            Retrieves all user sessions from local or remote computer(s).
    
            Note:   Requires query.exe in order to run
            Note:   This works against Windows Vista and later systems provided the following registry value is in place
                    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\AllowRemoteRPC = 1
            Note:   If query.exe takes longer than 15 seconds to return, an error is thrown and the next computername is processed.  Suppress this with -erroraction silentlycontinue
            Note:   If $sessions is empty, we return a warning saying no users.  Suppress this with -warningaction silentlycontinue

        .PARAMETER computername
            Name of computer(s) to run session query against
              
        .parameter parseIdleTime
            Parse idle time into a timespan object

        .parameter timeout
            Seconds to wait before ending query.exe process.  Helpful in situations where query.exe hangs due to the state of the remote system.
                    
        .FUNCTIONALITY
            Computers

        .EXAMPLE
            Get-usersession -computername "server1"

            Query all current user sessions on 'server1'

        .EXAMPLE
            Get-UserSession -computername $servers -parseIdleTime | ?{$_.idletime -gt [timespan]"1:00"} | ft -AutoSize

            Query all servers in the array $servers, parse idle time, check for idle time greater than 1 hour.

        .NOTES
            Thanks to Boe Prox for the ideas - http://learn-powershell.net/2010/11/01/quick-hit-find-currently-logged-on-users/

        .LINK
            http://gallery.technet.microsoft.com/Get-UserSessions-Parse-b4c97837

        #> 
            [cmdletbinding()]
            Param(
                [Parameter(
                    Position = 0,
                    ValueFromPipeline = $True)]
                [string[]]$ComputerName = "localhost",

                [switch]$ParseIdleTime,

                [validaterange(0, 120)]
                [int]$Timeout = 15
            )             
            Process {
                ForEach ($computer in $ComputerName) {
        
                    #start query.exe using .net and cmd /c.  We do this to avoid cases where query.exe hangs

                    #build temp file to store results.  Loop until we see the file
                    Try {
                        $Started = Get-Date
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        
                        Do {
                            start-sleep -Milliseconds 300
                            
                            if ( ((Get-Date) - $Started).totalseconds -gt 10) {
                                Throw "Timed out waiting for temp file '$TempFile'"
                            }
                        }
                        Until(Test-Path -Path $tempfile)
                    }
                    Catch {
                        Write-Error "Error for '$Computer': $_"
                        Continue
                    }

                    #Record date.  Start process to run query in cmd.  I use starttime independently of process starttime due to a few issues we ran into
                    $Started = Get-Date
                    $p = Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c query user /server:$computer > $tempfile" -WindowStyle hidden -passthru

                    #we can't read in info or else it will freeze.  We cant run waitforexit until we read the standard output, or we run into issues...
                    #handle timeouts on our own by watching hasexited
                    $stopprocessing = $false
                    do {
                    
                        #check if process has exited
                        $hasExited = $p.HasExited
                
                        #check if there is still a record of the process
                        Try {
                            $proc = Get-Process -id $p.id -ErrorAction stop
                        }
                        Catch {
                            $proc = $null
                        }

                        #sleep a bit
                        start-sleep -seconds .5

                        #If we timed out and the process has not exited, kill the process
                        if ( ( (Get-Date) - $Started ).totalseconds -gt $timeout -and -not $hasExited -and $proc) {
                            $p.kill()
                            $stopprocessing = $true
                            Remove-Item $tempfile -force
                            Write-Error "$computer`: Query.exe took longer than $timeout seconds to execute"
                        }
                    }
                    until($hasexited -or $stopProcessing -or -not $proc)
                    
                    if ($stopprocessing) {
                        Continue
                    }

                    #if we are still processing, read the output!
                    try {
                        $sessions = Get-Content $tempfile -ErrorAction stop
                        Remove-Item $tempfile -force
                    }
                    catch {
                        Write-Error "Could not process results for '$computer' in '$tempfile': $_"
                        continue
                    }
        
                    #handle no results
                    if ($sessions) {

                        1..($sessions.count - 1) | Foreach-Object {
            
                            #Start to build the custom object
                            $temp = "" | Select-Object ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
                            $temp.ComputerName = $computer

                            #The output of query.exe is dynamic. 
                            #strings should be 82 chars by default, but could reach higher depending on idle time.
                            #we use arrays to handle the latter.

                            if ($sessions[$_].length -gt 5) {
                        
                                #if the length is normal, parse substrings
                                if ($sessions[$_].length -le 82) {
                           
                                    $temp.Computer = $env:COMPUTERNAME
                                    $temp.Username = $sessions[$_].Substring(1, 22).trim()
                                    $temp.SessionName = $sessions[$_].Substring(23, 19).trim()
                                    $temp.Id = $sessions[$_].Substring(42, 4).trim()
                                    $temp.State = $sessions[$_].Substring(46, 8).trim()
                                    $temp.IdleTime = $sessions[$_].Substring(54, 11).trim()
                                    $logonTimeLength = $sessions[$_].length - 65
                                    try {
                                        $temp.LogonTime = Get-Date $sessions[$_].Substring(65, $logonTimeLength).trim() -ErrorAction stop
                                    }
                                    catch {
                                        #Cleaning up code, investigate reason behind this.  Long way of saying $null....
                                        $temp.LogonTime = $sessions[$_].Substring(65, $logonTimeLength).trim() | Out-Null
                                    }

                                }
                        
                                #Otherwise, create array and parse
                                else {                                       
                                    $array = $sessions[$_] -replace "\s+", " " -split " "
                                    $temp.Username = $array[1]
                
                                    #in some cases the array will be missing the session name.  array indices change
                                    if ($array.count -lt 9) {
                                        $temp.SessionName = ""
                                        $temp.Id = $array[2]
                                        $temp.State = $array[3]
                                        $temp.IdleTime = $array[4]
                                        try {
                                            $temp.LogonTime = Get-Date $($array[5] + " " + $array[6] + " " + $array[7]) -ErrorAction stop
                                        }
                                        catch {
                                            $temp.LogonTime = ($array[5] + " " + $array[6] + " " + $array[7]).trim()
                                        }
                                    }
                                    else {
                                        $temp.SessionName = $array[2]
                                        $temp.Id = $array[3]
                                        $temp.State = $array[4]
                                        $temp.IdleTime = $array[5]
                                        try {
                                            $temp.LogonTime = Get-Date $($array[6] + " " + $array[7] + " " + $array[8]) -ErrorAction stop
                                        }
                                        catch {
                                            $temp.LogonTime = ($array[6] + " " + $array[7] + " " + $array[8]).trim()
                                        }
                                    }
                                }

                                #if specified, parse idle time to timespan
                                if ($parseIdleTime) {
                                    $string = $temp.idletime
                
                                    #quick function to handle minutes or hours:minutes
                                    function Convert-ShortIdle {
                                        param($string)
                                        if ($string -match "\:") {
                                            [timespan]$string
                                        }
                                        else {
                                            New-TimeSpan -Minutes $string
                                        }
                                    }
                
                                    #to the left of + is days
                                    if ($string -match "\+") {
                                        $days = New-TimeSpan -days ($string -split "\+")[0]
                                        $hourMin = Convert-ShortIdle ($string -split "\+")[1]
                                        $temp.idletime = $days + $hourMin
                                    }
                                    #. means less than a minute
                                    elseif ($string -like "." -or $string -like "none") {
                                        $temp.idletime = [timespan]"0:00"
                                    }
                                    #hours and minutes
                                    else {
                                        $temp.idletime = Convert-ShortIdle $string
                                    }
                                }
                
                                #Output the result
                                $temp.ComputerName = $env:COMPUTERNAME
                                $temp

                            }
                        }
                    }            
                    else {

                        $properties = @{

                            computername = $env:COMPUTERNAME
                            idletime     = "No user session"
                            Username     = "No user session"
                            LogonTime    = "No user session"
                            State        = "Active"

                        }
                        $output = New-Object psobject -Property $properties
                        $output
                        

                    }
                }
            }
        }
        Function IsUEFI {

            <#
.Synopsis
   Determines underlying firmware (BIOS) type and returns True for UEFI or False for legacy BIOS.
.DESCRIPTION
   This function uses a complied Win32 API call to determine the underlying system firmware type.
.EXAMPLE
   If (IsUEFI) { # System is running UEFI firmware... }
.OUTPUTS
   [Bool] True = UEFI Firmware; False = Legacy BIOS
.FUNCTIONALITY
   Determines underlying system firmware type
#>

            [OutputType([Bool])]
            Param ()

            Add-Type -Language CSharp -TypeDefinition @'

    using System;
    using System.Runtime.InteropServices;

    public class CheckUEFI
    {
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern UInt32 
        GetFirmwareEnvironmentVariableA(string lpName, string lpGuid, IntPtr pBuffer, UInt32 nSize);

        const int ERROR_INVALID_FUNCTION = 1; 

        public static bool IsUEFI()
        {
            // Try to call the GetFirmwareEnvironmentVariable API.  This is invalid on legacy BIOS.

            GetFirmwareEnvironmentVariableA("","{00000000-0000-0000-0000-000000000000}",IntPtr.Zero,0);

            if (Marshal.GetLastWin32Error() == ERROR_INVALID_FUNCTION)

                return false;     // API not supported; this is a legacy BIOS

            else

                return true;      // API error (expected) but call is supported.  This is UEFI.
        }
    }
'@


            [CheckUEFI]::IsUEFI()
        }
        Function Get-BiosType {

            <#
.Synopsis
   Determines underlying firmware (BIOS) type and returns an integer indicating UEFI, Legacy BIOS or Unknown.
   Supported on Windows 8/Server 2012 or later
.DESCRIPTION
   This function uses a complied Win32 API call to determine the underlying system firmware type.
.EXAMPLE
   If (Get-BiosType -eq 1) { # System is running UEFI firmware... }
.EXAMPLE
    Switch (Get-BiosType) {
        1       {"Legacy BIOS"}
        2       {"UEFI"}
        Default {"Unknown"}
    }
.OUTPUTS
   Integer indicating firmware type (1 = Legacy BIOS, 2 = UEFI, Other = Unknown)
.FUNCTIONALITY
   Determines underlying system firmware type
#>

            [OutputType([UInt32])]
            Param()

            Add-Type -Language CSharp -TypeDefinition @'

    using System;
    using System.Runtime.InteropServices;

    public class FirmwareType
    {
        [DllImport("kernel32.dll")]
        static extern bool GetFirmwareType(ref uint FirmwareType);

        public static uint GetFirmwareType()
        {
            uint firmwaretype = 0;
            if (GetFirmwareType(ref firmwaretype))
                return firmwaretype;
            else
                return 0;   // API call failed, just return 'unknown'
        }
    }
'@


            [FirmwareType]::GetFirmwareType()
        }

        $SDC = reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation\ /v Model | 
        Select-String Model
        $SDC = $SDC -replace "Model    REG_SZ", ""
        $SDC = $SDC -replace "NIPRNet", ""
        $SDC = $SDC.Trim()

        $data = $null
    
        $count = 0
        while ($data.State -ne "Active" -and $count -le 10) {

            $data = Get-UserSession | Where-Object { $_.State -like "*Active*" }
            if ($data.State -ne "Active") { Start-Sleep 1; $count += 1 }

        }

        $data.LogonTime = $data.LogonTime.ToString()

        Add-Member -InputObject $data -Name "SDC" -Value $SDC -MemberType NoteProperty
    
        $make = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer

        $make = $make.Manufacturer
        $make = $make -replace "Hewlett-Packard", "HP"
        $make = $make -replace "Panasonic Corporation", "Panasonic"
        $make = $make -replace "Gigabyte Technology Co., Ltd.", "Gigabyte"
        $make = $make -replace "Microsoft Corporation", "Microsoft"
        $make = $make -replace "Ace Computers", "Ace"
        $make = $make -replace "Dell Inc.", "Dell"
    
        Add-Member -InputObject $data -Name "Make" -Value $make -MemberType NoteProperty
        $make = $make.Manufacturer.ToLower()
    
        if ($make -eq "lenovo") { $model = wmic csproduct get version }
        else { $model = (Get-WmiObject -Class:Win32_ComputerSystem).Model }
        $model = $model -join " "
        $model = $model -replace "Version", ""
        $model = $model.Trim()
        $model = $model -replace "A3009DD10303", "HP ProBook 650 G1"
        $model = $model -replace "Ace LogiCAD 45525 Performance Desktop System", "Ace LogiCAD"
        $model = $model -replace "Mobile Workstation", ""
        $model = $model -replace "QEB2020A", ""
        $model = $model -replace "QEB19B", ""
        $model = $model -replace "QEB18B", ""
        $model = $model -replace "NOTEBOOK PC", ""
        $model = $model -replace "2-in-1 QEB 2020B", ""
        Add-Member -InputObject $data -Name "Model" -Value $model -MemberType NoteProperty

        $ip = Test-Connection -ComputerName (hostname) -Count 1  | Select-Object IPV4Address
        Add-Member -InputObject $data -Name "IP" -Value $ip.IPV4Address.ToString() -MemberType NoteProperty

        $bios = Get-BiosType
        if ($bios -eq 1) { $bios = "Legacy BIOS" }
        elseif ($bios -eq 2) { $bios = "UEFI" }
        else { $bios = "Other" }

        Add-Member -InputObject $data -Name "BIOS" -Value $bios -MemberType NoteProperty

        $secureBoot = Confirm-SecureBootUEFI
        if ($secureBoot -eq $true) { $secureBoot = "Enabled" }
        elseif ($secureBoot -eq $false) { $secureBoot = "Disabled" }
        else { $secureBoot = "Other" }
        Add-Member -InputObject $data -Name "SecureBoot" -Value $secureBoot -MemberType NoteProperty


        $data | ConvertTo-Json | Invoke-WebRequest -Uri $outputURI -Method Post -ContentType 'application/json'
 
    }
    
    Write-Host "Sending out job to computers`n"


    foreach ($pc in $computers) {

        try {

            Invoke-Command -ComputerName $pc -ScriptBlock $scriptblock -ArgumentList $outputURI -AsJob > $null

        }
        catch {

            Write-Host "Failed: "$_
        
        }
    }

    Write-Host "Job Distribution Complete!"

}