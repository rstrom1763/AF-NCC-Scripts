#A1C Strom

Function Send-Job {

    Param(

        [string]$ComputerOU, #OU path to computer OU to target
        [string]$ComputerList, #Path to text file containing all of the computers to target
        [Parameter(Mandatory = $True)]$outputURI  #Url of the machine running the Nodejs application Ex: http://computername:8081/write

    )

    if ($ComputerOU -ne "" -and $ComputerList -eq "") {
        try {
            $computers = Get-ADComputer -Filter * -SearchBase $ComputerOU
        }
        catch {
            Write-Error "Could not fetch computers from Active Directory `n`n$_"
            return
        }
    }
    elseif ($ComputerList -ne "" -and $ComputerOU -eq "") {
        try {
            $computers = Get-Content $ComputerList
        }
        catch {
            Write-Error "Could not import computer list `n`n$_"
            return
        }
    }
    elseif ($ComputerList -ne "" -and $ComputerOU -ne "") {
        Set-Content "C:/strom/test.txt" -Value "list "$ComputerList" OU "$ComputerOU" |"
        return
    }
    elseif ($ComputerList -eq "" -and $ComputerOU -eq "") {
        Write-Error "Must choose targets using either ComputerList or computerOU`n`n$_"
        return
    }
    else {
        Write-Error "I don't know what you did but it was wrong: 1`n`n$_"
        return
    }

    if ($null -ne $computers.name) {
        try {
            $computers = $computers.name | Invoke-Ping -Quiet #Relies on Invoke-Ping Module
        }
        catch {
            Write-Error "Could not ping the computers from the OU`n`n$_"
            return
        }
    }
    elseif ($null -eq $computers.name) {
        try {
            $computers = $computers | Invoke-Ping -Quiet #Relies on Invoke-Ping Module
        }
        catch {
            Write-Error "Could not ping computers from the computer list`n`n$_"
            return
        }
    }
    else {
        Write-Error "I don't know what you did but it was wrong: 2`n`n$_"
        return
    }
    
    Remove-Job -State Stopped, Failed

    $scriptblock = {
        
        param(
            $outputURI
        )
        
        if (!(Test-Path -Path "C:/temp")) {
            New-Item -Path "C:/" -Name "temp" -ItemType Directory
        }

        function Add-Log {
            #Adds entry to log file
            param(
                [Parameter(Mandatory = $True)][string]$Value
            )
            $hostname = hostname
            Add-Content "C:/temp/$hostname.log" -Value "$Value $(Get-Date)"
        }
        function Reset-Log {
            #Empties out log file
            $hostname = hostname
            Set-Content "C:/temp/$hostname.log" -Value $null
        }
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
                           
                                    $temp.ComputerName = $env:COMPUTERNAME
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

        $hostname = hostname
        Reset-Log #Clear the local log

        try {
            $data = Get-UserSession | Where-Object { $_.State -like "*Active*" }
            if (($data | Measure-Object).Count -eq 0) { 
                $data = Get-UserSession | Sort-Object -Property LogonTime -Descending 
            }
            $data = $data[0]
            $data.LogonTime = $data.LogonTime.ToString()
            Add-Log -Value "Success $data".Replace("`n", "")
        }
        catch {
            Add-Log -Value "Failed user session collection: $_"
        }

        try {
            $SDC = reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation\ /v Model | 
            Select-String Model
            $SDC = $SDC -replace "Model    REG_SZ", ""
            $SDC = $SDC -replace "NIPRNet", ""
            $SDC = $SDC.Trim()
            Add-Member -InputObject $data -Name "SDC" -Value $SDC -MemberType NoteProperty
            Add-Log -Value "Success: SDC collection"
        }
        catch {
            Add-Log -Value "Fail: SDC Collection: $_"
        }

        try {
            $make = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer
            $make = $make.Manufacturer
            Add-Member -InputObject $data -Name "Make" -Value $make -MemberType NoteProperty
            $make = $make.ToLower()
            Add-Log -Value "Success: Make collection"
        }
        catch {
            Add-Log -Value "Fail: Make collection: $_"
        }
    
        try {
            if ($make -eq "lenovo") { $model = wmic csproduct get version }
            else { $model = (Get-WmiObject -Class:Win32_ComputerSystem).Model }
            $model = $model -join " "
            $model = $model -replace "Version", ""
            $model = $model.Trim()
            Add-Member -InputObject $data -Name "Model" -Value $model -MemberType NoteProperty
            Add-Log -Value "Success: Model collection"
        }
        catch {
            Add-Log -Value "Fail: Model collection: $_"
        }

        try {
            $serial = (Get-WmiObject win32_bios).Serialnumber
            Add-Member -InputObject $data -Name "Serial Number" -Value $serial -MemberType NoteProperty
            Add-Log -Value "Success: Serial collection"
        }
        catch {
            Add-Log -Value "Fail: Serial collection: $_"
        }

        try {
            $ip = Test-Connection -ComputerName (hostname) -Count 1  | Select-Object IPV4Address
            Add-Member -InputObject $data -Name "IP" -Value $ip.IPV4Address.ToString() -MemberType NoteProperty
            Add-Log -Value "Success: IP collection"
        }
        catch {
            Add-Log -Value "Fail: IP Collection: $_"
        }

        try {
            $bios = Get-BiosType
            if ($bios -eq 1) { $bios = "Legacy BIOS" }
            elseif ($bios -eq 2) { $bios = "UEFI" }
            else { $bios = "Other" }
            Add-Member -InputObject $data -Name "BIOS" -Value $bios -MemberType NoteProperty
            Add-Log -Value "Success: BIOS collection"
        }
        catch {
            Add-Log -Value "Fail: BIOS collection: $_"
        }

        try {
            $profiles = (Get-ChildItem "C:/users" | Measure-Object).Count
            Add-Member -InputObject $data -Name "Profiles" -Value $profiles -MemberType NoteProperty
            Add-Log -Value "Success: Profile collection"
        }
        catch {
            Add-Log -Value "Fail: Profile collection: $_"
        }

        try {
            $secureBoot = Confirm-SecureBootUEFI
            if ($secureBoot -eq $true) { $secureBoot = "Enabled" }
            elseif ($secureBoot -eq $false) { $secureBoot = "Disabled" }
            else { $secureBoot = "Other" }
            Add-Member -InputObject $data -Name "SecureBoot" -Value $secureBoot -MemberType NoteProperty
            Add-Log -Value "Success: Profile collection"
        }
        catch {
            Add-Log -Value "Fail: Profile collection: $_"
        }

        Add-Member -InputObject $data -Name "EntryDate" -Value ((Get-Date).ToString()) -MemberType NoteProperty

        Add-Member -InputObject $data -Name "LastReboot" -Value (Get-CimInstance -ClassName win32_operatingsystem | 
            Select-Object csname, lastbootuptime).lastbootuptime.tostring() -MemberType NoteProperty

        $data = $data | Select-Object -Property * -ExcludeProperty idletime, id, sessionname |  ConvertTo-Json

        try {
            Invoke-WebRequest -Uri $outputURI -Body $data -Method Post -ContentType 'application/json' -UseBasicParsing
            Add-Log -Value "Success: POST request: $data"
        }
        catch {
            Add-Log -Value "Fail: POST request: $_"
        }
        Set-Content -Path "C:/temp/$(hostname).json" -Value $data
        Add-Log -Value "Finished"

    }

    Remove-Job -State Stopped, Failed
    $totalCount = ($computers | Measure-Object).Count
    $count = 0

    Write-Host "Sending Job to $totalCount computers. "

    foreach ($pc in $computers) {

        try {

            Start-Sleep -Milliseconds 10
            Invoke-Command -ComputerName $pc -ScriptBlock $scriptblock -ArgumentList $outputURI -AsJob > $null

        }
        catch {

            Write-Host "Failed: $_"
        
        }

        $count++
        [int]$percentComplete = ($count / $totalCount) * 100
        Write-Progress -Activity "Sending Jobs: " -Status "Status: $percentComplete%   $count out of $totalCount" -PercentComplete $percentComplete

    }

    Write-Host "Job Distribution Complete! "

}
Function Invoke-Ping 
{
<#
.SYNOPSIS
    Ping or test connectivity to systems in parallel
    
.DESCRIPTION
    Ping or test connectivity to systems in parallel

    Default action will run a ping against systems
        If Quiet parameter is specified, we return an array of systems that responded
        If Detail parameter is specified, we test WSMan, RemoteReg, RPC, RDP and/or SMB

.PARAMETER ComputerName
    One or more computers to test

.PARAMETER Quiet
    If specified, only return addresses that responded to Test-Connection

.PARAMETER Detail
    Include one or more additional tests as specified:
        WSMan      via Test-WSMan
        RemoteReg  via Microsoft.Win32.RegistryKey
        RPC        via WMI
        RDP        via port 3389
        SMB        via \\ComputerName\C$
        *          All tests

.PARAMETER Timeout
    Time in seconds before we attempt to dispose an individual query.  Default is 20

.PARAMETER Throttle
    Throttle query to this many parallel runspaces.  Default is 100.

.PARAMETER NoCloseOnTimeout
    Do not dispose of timed out tasks or attempt to close the runspace if threads have timed out

    This will prevent the script from hanging in certain situations where threads become non-responsive, at the expense of leaking memory within the PowerShell host.

.EXAMPLE
    Invoke-Ping Server1, Server2, Server3 -Detail *

    # Check for WSMan, Remote Registry, Remote RPC, RDP, and SMB (via C$) connectivity against 3 machines

.EXAMPLE
    $Computers | Invoke-Ping

    # Ping computers in $Computers in parallel

.EXAMPLE
    $Responding = $Computers | Invoke-Ping -Quiet
    
    # Create a list of computers that successfully responded to Test-Connection

.LINK
    https://gallery.technet.microsoft.com/scriptcenter/Invoke-Ping-Test-in-b553242a

.FUNCTIONALITY
    Computers

#>
    [cmdletbinding(DefaultParameterSetName='Ping')]
    param(
        [Parameter( ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true, 
                    Position=0)]
        [string[]]$ComputerName,
        
        [Parameter( ParameterSetName='Detail')]
        [validateset("*","WSMan","RemoteReg","RPC","RDP","SMB")]
        [string[]]$Detail,
        
        [Parameter(ParameterSetName='Ping')]
        [switch]$Quiet,
        
        [int]$Timeout = 20,
        
        [int]$Throttle = 100,

        [switch]$NoCloseOnTimeout
    )
    Begin
    {

        #http://gallery.technet.microsoft.com/Run-Parallel-Parallel-377fd430
        function Invoke-Parallel {
            [cmdletbinding(DefaultParameterSetName='ScriptBlock')]
            Param (   
                [Parameter(Mandatory=$false,position=0,ParameterSetName='ScriptBlock')]
                    [System.Management.Automation.ScriptBlock]$ScriptBlock,

                [Parameter(Mandatory=$false,ParameterSetName='ScriptFile')]
                [ValidateScript({test-path $_ -pathtype leaf})]
                    $ScriptFile,

                [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
                [Alias('CN','__Server','IPAddress','Server','ComputerName')]    
                    [PSObject]$InputObject,

                    [PSObject]$Parameter,

                    [switch]$ImportVariables,

                    [switch]$ImportModules,

                    [int]$Throttle = 20,

                    [int]$SleepTimer = 200,

                    [int]$RunspaceTimeout = 0,

			        [switch]$NoCloseOnTimeout = $false,

                    [int]$MaxQueue,

                [validatescript({Test-Path (Split-Path $_ -parent)})]
                    [string]$LogFile = "C:\temp\log.log",

			        [switch] $Quiet = $false
            )
    
            Begin {
                
                #No max queue specified?  Estimate one.
                #We use the script scope to resolve an odd PowerShell 2 issue where MaxQueue isn't seen later in the function
                if( -not $PSBoundParameters.ContainsKey('MaxQueue') )
                {
                    if($RunspaceTimeout -ne 0){ $script:MaxQueue = $Throttle }
                    else{ $script:MaxQueue = $Throttle * 3 }
                }
                else
                {
                    $script:MaxQueue = $MaxQueue
                }

                Write-Verbose "Throttle: '$throttle' SleepTimer '$sleepTimer' runSpaceTimeout '$runspaceTimeout' maxQueue '$maxQueue' logFile '$logFile'"

                #If they want to import variables or modules, create a clean runspace, get loaded items, use those to exclude items
                if ($ImportVariables -or $ImportModules)
                {
                    $StandardUserEnv = [powershell]::Create().addscript({

                        #Get modules and snapins in this clean runspace
                        $Modules = Get-Module | Select -ExpandProperty Name
                        $Snapins = Get-PSSnapin | Select -ExpandProperty Name

                        #Get variables in this clean runspace
                        #Called last to get vars like $? into session
                        $Variables = Get-Variable | Select -ExpandProperty Name
                
                        #Return a hashtable where we can access each.
                        @{
                            Variables = $Variables
                            Modules = $Modules
                            Snapins = $Snapins
                        }
                    }).invoke()[0]
            
                    if ($ImportVariables) {
                        #Exclude common parameters, bound parameters, and automatic variables
                        Function _temp {[cmdletbinding()] param() }
                        $VariablesToExclude = @( (Get-Command _temp | Select -ExpandProperty parameters).Keys + $PSBoundParameters.Keys + $StandardUserEnv.Variables )
                        Write-Verbose "Excluding variables $( ($VariablesToExclude | sort ) -join ", ")"

                        # we don't use 'Get-Variable -Exclude', because it uses regexps. 
                        # One of the veriables that we pass is '$?'. 
                        # There could be other variables with such problems.
                        # Scope 2 required if we move to a real module
                        $UserVariables = @( Get-Variable | Where { -not ($VariablesToExclude -contains $_.Name) } ) 
                        Write-Verbose "Found variables to import: $( ($UserVariables | Select -expandproperty Name | Sort ) -join ", " | Out-String).`n"

                    }

                    if ($ImportModules) 
                    {
                        $UserModules = @( Get-Module | Where {$StandardUserEnv.Modules -notcontains $_.Name -and (Test-Path $_.Path -ErrorAction SilentlyContinue)} | Select -ExpandProperty Path )
                        $UserSnapins = @( Get-PSSnapin | Select -ExpandProperty Name | Where {$StandardUserEnv.Snapins -notcontains $_ } ) 
                    }
                }

                #region functions
            
                    Function Get-RunspaceData {
                        [cmdletbinding()]
                        param( [switch]$Wait )

                        #loop through runspaces
                        #if $wait is specified, keep looping until all complete
                        Do {

                            #set more to false for tracking completion
                            $more = $false

                            #Progress bar if we have inputobject count (bound parameter)
                            if (-not $Quiet) {
						        Write-Progress  -Activity "Running Query" -Status "Starting threads"`
							        -CurrentOperation "$startedCount threads defined - $totalCount input objects - $script:completedCount input objects processed"`
							        -PercentComplete $( Try { $script:completedCount / $totalCount * 100 } Catch {0} )
					        }

                            #run through each runspace.           
                            Foreach($runspace in $runspaces) {
                    
                                #get the duration - inaccurate
                                $currentdate = Get-Date
                                $runtime = $currentdate - $runspace.startTime
                                $runMin = [math]::Round( $runtime.totalminutes ,2 )

                                #set up log object
                                $log = "" | select Date, Action, Runtime, Status, Details
                                $log.Action = "Removing:'$($runspace.object)'"
                                $log.Date = $currentdate
                                $log.Runtime = "$runMin minutes"

                                #If runspace completed, end invoke, dispose, recycle, counter++
                                If ($runspace.Runspace.isCompleted) {
                            
                                    $script:completedCount++
                        
                                    #check if there were errors
                                    if($runspace.powershell.Streams.Error.Count -gt 0) {
                                
                                        #set the logging info and move the file to completed
                                        $log.status = "CompletedWithErrors"
                                        Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                        foreach($ErrorRecord in $runspace.powershell.Streams.Error) {
                                            Write-Error -ErrorRecord $ErrorRecord
                                        }
                                    }
                                    else {
                                
                                        #add logging details and cleanup
                                        $log.status = "Completed"
                                        Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                    }

                                    #everything is logged, clean up the runspace
                                    $runspace.powershell.EndInvoke($runspace.Runspace)
                                    $runspace.powershell.dispose()
                                    $runspace.Runspace = $null
                                    $runspace.powershell = $null

                                }

                                #If runtime exceeds max, dispose the runspace
                                ElseIf ( $runspaceTimeout -ne 0 -and $runtime.totalseconds -gt $runspaceTimeout) {
                            
                                    $script:completedCount++
                                    $timedOutTasks = $true
                            
							        #add logging details and cleanup
                                    $log.status = "TimedOut"
                                    Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                    Write-Error "Runspace timed out at $($runtime.totalseconds) seconds for the object:`n$($runspace.object | out-string)"

                                    #Depending on how it hangs, we could still get stuck here as dispose calls a synchronous method on the powershell instance
                                    if (!$noCloseOnTimeout) { $runspace.powershell.dispose() }
                                    $runspace.Runspace = $null
                                    $runspace.powershell = $null
                                    $completedCount++

                                }
                   
                                #If runspace isn't null set more to true  
                                ElseIf ($runspace.Runspace -ne $null ) {
                                    $log = $null
                                    $more = $true
                                }

                                #log the results if a log file was indicated
                                if($logFile -and $log){
                                    ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1] | out-file $LogFile -append
                                }
                            }

                            #Clean out unused runspace jobs
                            $temphash = $runspaces.clone()
                            $temphash | Where { $_.runspace -eq $Null } | ForEach {
                                $Runspaces.remove($_)
                            }

                            #sleep for a bit if we will loop again
                            if($PSBoundParameters['Wait']){ Start-Sleep -milliseconds $SleepTimer }

                        #Loop again only if -wait parameter and there are more runspaces to process
                        } while ($more -and $PSBoundParameters['Wait'])
                
                    #End of runspace function
                    }

                #endregion functions
        
                #region Init

                    if($PSCmdlet.ParameterSetName -eq 'ScriptFile')
                    {
                        $ScriptBlock = [scriptblock]::Create( $(Get-Content $ScriptFile | out-string) )
                    }
                    elseif($PSCmdlet.ParameterSetName -eq 'ScriptBlock')
                    {
                        #Start building parameter names for the param block
                        [string[]]$ParamsToAdd = '$_'
                        if( $PSBoundParameters.ContainsKey('Parameter') )
                        {
                            $ParamsToAdd += '$Parameter'
                        }

                        $UsingVariableData = $Null
                

                        # This code enables $Using support through the AST.
                        # This is entirely from  Boe Prox, and his https://github.com/proxb/PoshRSJob module; all credit to Boe!
                
                        if($PSVersionTable.PSVersion.Major -gt 2)
                        {
                            #Extract using references
                            $UsingVariables = $ScriptBlock.ast.FindAll({$args[0] -is [System.Management.Automation.Language.UsingExpressionAst]},$True)    

                            If ($UsingVariables)
                            {
                                $List = New-Object 'System.Collections.Generic.List`1[System.Management.Automation.Language.VariableExpressionAst]'
                                ForEach ($Ast in $UsingVariables)
                                {
                                    [void]$list.Add($Ast.SubExpression)
                                }

                                $UsingVar = $UsingVariables | Group Parent | ForEach {$_.Group | Select -First 1}
        
                                #Extract the name, value, and create replacements for each
                                $UsingVariableData = ForEach ($Var in $UsingVar) {
                                    Try
                                    {
                                        $Value = Get-Variable -Name $Var.SubExpression.VariablePath.UserPath -ErrorAction Stop
                                        $NewName = ('$__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                        [pscustomobject]@{
                                            Name = $Var.SubExpression.Extent.Text
                                            Value = $Value.Value
                                            NewName = $NewName
                                            NewVarName = ('__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                        }
                                        $ParamsToAdd += $NewName
                                    }
                                    Catch
                                    {
                                        Write-Error "$($Var.SubExpression.Extent.Text) is not a valid Using: variable!"
                                    }
                                }
    
                                $NewParams = $UsingVariableData.NewName -join ', '
                                $Tuple = [Tuple]::Create($list, $NewParams)
                                $bindingFlags = [Reflection.BindingFlags]"Default,NonPublic,Instance"
                                $GetWithInputHandlingForInvokeCommandImpl = ($ScriptBlock.ast.gettype().GetMethod('GetWithInputHandlingForInvokeCommandImpl',$bindingFlags))
        
                                $StringScriptBlock = $GetWithInputHandlingForInvokeCommandImpl.Invoke($ScriptBlock.ast,@($Tuple))

                                $ScriptBlock = [scriptblock]::Create($StringScriptBlock)

                                Write-Verbose $StringScriptBlock
                            }
                        }
                
                        $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param($($ParamsToAdd -Join ", "))`r`n" + $Scriptblock.ToString())
                    }
                    else
                    {
                        Throw "Must provide ScriptBlock or ScriptFile"; Break
                    }

                    Write-Debug "`$ScriptBlock: $($ScriptBlock | Out-String)"
                    Write-Verbose "Creating runspace pool and session states"

                    #If specified, add variables and modules/snapins to session state
                    $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                    if ($ImportVariables)
                    {
                        if($UserVariables.count -gt 0)
                        {
                            foreach($Variable in $UserVariables)
                            {
                                $sessionstate.Variables.Add( (New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Variable.Name, $Variable.Value, $null) )
                            }
                        }
                    }
                    if ($ImportModules)
                    {
                        if($UserModules.count -gt 0)
                        {
                            foreach($ModulePath in $UserModules)
                            {
                                $sessionstate.ImportPSModule($ModulePath)
                            }
                        }
                        if($UserSnapins.count -gt 0)
                        {
                            foreach($PSSnapin in $UserSnapins)
                            {
                                [void]$sessionstate.ImportPSSnapIn($PSSnapin, [ref]$null)
                            }
                        }
                    }

                    #Create runspace pool
                    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
                    $runspacepool.Open() 

                    Write-Verbose "Creating empty collection to hold runspace jobs"
                    $Script:runspaces = New-Object System.Collections.ArrayList        
        
                    #If inputObject is bound get a total count and set bound to true
                    $global:__bound = $false
                    $allObjects = @()
                    if( $PSBoundParameters.ContainsKey("inputObject") ){
                        $global:__bound = $true
                    }

                    #Set up log file if specified
                    if( $LogFile ){
                        New-Item -ItemType file -path $logFile -force | Out-Null
                        ("" | Select Date, Action, Runtime, Status, Details | ConvertTo-Csv -NoTypeInformation -Delimiter ";")[0] | Out-File $LogFile
                    }

                    #write initial log entry
                    $log = "" | Select Date, Action, Runtime, Status, Details
                        $log.Date = Get-Date
                        $log.Action = "Batch processing started"
                        $log.Runtime = $null
                        $log.Status = "Started"
                        $log.Details = $null
                        if($logFile) {
                            ($log | convertto-csv -Delimiter ";" -NoTypeInformation)[1] | Out-File $LogFile -Append
                        }

			        $timedOutTasks = $false

                #endregion INIT
            }

            Process {

                #add piped objects to all objects or set all objects to bound input object parameter
                if( -not $global:__bound ){
                    $allObjects += $inputObject
                }
                else{
                    $allObjects = $InputObject
                }
            }

            End {
        
                #Use Try/Finally to catch Ctrl+C and clean up.
                Try
                {
                    #counts for progress
                    $totalCount = $allObjects.count
                    $script:completedCount = 0
                    $startedCount = 0

                    foreach($object in $allObjects){
        
                        #region add scripts to runspace pool
                    
                            #Create the powershell instance, set verbose if needed, supply the scriptblock and parameters
                            $powershell = [powershell]::Create()
                    
                            if ($VerbosePreference -eq 'Continue')
                            {
                                [void]$PowerShell.AddScript({$VerbosePreference = 'Continue'})
                            }

                            [void]$PowerShell.AddScript($ScriptBlock).AddArgument($object)

                            if ($parameter)
                            {
                                [void]$PowerShell.AddArgument($parameter)
                            }

                            # $Using support from Boe Prox
                            if ($UsingVariableData)
                            {
                                Foreach($UsingVariable in $UsingVariableData) {
                                    Write-Verbose "Adding $($UsingVariable.Name) with value: $($UsingVariable.Value)"
                                    [void]$PowerShell.AddArgument($UsingVariable.Value)
                                }
                            }

                            #Add the runspace into the powershell instance
                            $powershell.RunspacePool = $runspacepool
    
                            #Create a temporary collection for each runspace
                            $temp = "" | Select-Object PowerShell, StartTime, object, Runspace
                            $temp.PowerShell = $powershell
                            $temp.StartTime = Get-Date
                            $temp.object = $object
    
                            #Save the handle output when calling BeginInvoke() that will be used later to end the runspace
                            $temp.Runspace = $powershell.BeginInvoke()
                            $startedCount++

                            #Add the temp tracking info to $runspaces collection
                            Write-Verbose ( "Adding {0} to collection at {1}" -f $temp.object, $temp.starttime.tostring() )
                            $runspaces.Add($temp) | Out-Null
            
                            #loop through existing runspaces one time
                            Get-RunspaceData

                            #If we have more running than max queue (used to control timeout accuracy)
                            #Script scope resolves odd PowerShell 2 issue
                            $firstRun = $true
                            while ($runspaces.count -ge $Script:MaxQueue) {

                                #give verbose output
                                if($firstRun){
                                    Write-Verbose "$($runspaces.count) items running - exceeded $Script:MaxQueue limit."
                                }
                                $firstRun = $false
                    
                                #run get-runspace data and sleep for a short while
                                Get-RunspaceData
                                Start-Sleep -Milliseconds $sleepTimer
                    
                            }

                        #endregion add scripts to runspace pool
                    }
                     
                    Write-Verbose ( "Finish processing the remaining runspace jobs: {0}" -f ( @($runspaces | Where {$_.Runspace -ne $Null}).Count) )
                    Get-RunspaceData -wait

                    if (-not $quiet) {
			            Write-Progress -Activity "Running Query" -Status "Starting threads" -Completed
		            }

                }
                Finally
                {
                    #Close the runspace pool, unless we specified no close on timeout and something timed out
                    if ( ($timedOutTasks -eq $false) -or ( ($timedOutTasks -eq $true) -and ($noCloseOnTimeout -eq $false) ) ) {
	                    Write-Verbose "Closing the runspace pool"
			            $runspacepool.close()
                    }

                    #collect garbage
                    [gc]::Collect()
                }       
            }
        }

        Write-Verbose "PSBoundParameters = $($PSBoundParameters | Out-String)"
        
        $bound = $PSBoundParameters.keys -contains "ComputerName"
        if(-not $bound)
        {
            [System.Collections.ArrayList]$AllComputers = @()
        }
    }
    Process
    {

        #Handle both pipeline and bound parameter.  We don't want to stream objects, defeats purpose of parallelizing work
        if($bound)
        {
            $AllComputers = $ComputerName
        }
        Else
        {
            foreach($Computer in $ComputerName)
            {
                $AllComputers.add($Computer) | Out-Null
            }
        }

    }
    End
    {

        #Built up the parameters and run everything in parallel
        $params = @($Detail, $Quiet)
        $splat = @{
            Throttle = $Throttle
            RunspaceTimeout = $Timeout
            InputObject = $AllComputers
            parameter = $params
        }
        if($NoCloseOnTimeout)
        {
            $splat.add('NoCloseOnTimeout',$True)
        }

        Invoke-Parallel @splat -ScriptBlock {
        
            $computer = $_.trim()
            $detail = $parameter[0]
            $quiet = $parameter[1]

            #They want detail, define and run test-server
            if($detail)
            {
                Try
                {
                    #Modification of jrich's Test-Server function: https://gallery.technet.microsoft.com/scriptcenter/Powershell-Test-Server-e0cdea9a
                    Function Test-Server{
                        [cmdletBinding()]
                        param(
	                        [parameter(
                                Mandatory=$true,
                                ValueFromPipeline=$true)]
	                        [string[]]$ComputerName,
                            [switch]$All,
                            [parameter(Mandatory=$false)]
	                        [switch]$CredSSP,
                            [switch]$RemoteReg,
                            [switch]$RDP,
                            [switch]$RPC,
                            [switch]$SMB,
                            [switch]$WSMAN,
                            [switch]$IPV6,
	                        [Management.Automation.PSCredential]$Credential
                        )
                            begin
                            {
	                            $total = Get-Date
	                            $results = @()
	                            if($credssp -and -not $Credential)
                                {
                                    Throw "Must supply Credentials with CredSSP test"
                                }

                                [string[]]$props = write-output Name, IP, Domain, Ping, WSMAN, CredSSP, RemoteReg, RPC, RDP, SMB

                                #Hash table to create PSObjects later, compatible with ps2...
                                $Hash = @{}
                                foreach($prop in $props)
                                {
                                    $Hash.Add($prop,$null)
                                }

                                function Test-Port{
                                    [cmdletbinding()]
                                    Param(
                                        [string]$srv,
                                        $port=135,
                                        $timeout=3000
                                    )
                                    $ErrorActionPreference = "SilentlyContinue"
                                    $tcpclient = new-Object system.Net.Sockets.TcpClient
                                    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
                                    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
                                    if(-not $wait)
                                    {
                                        $tcpclient.Close()
                                        Write-Verbose "Connection Timeout to $srv`:$port"
                                        $false
                                    }
                                    else
                                    {
                                        Try
                                        {
                                            $tcpclient.EndConnect($iar) | out-Null
                                            $true
                                        }
                                        Catch
                                        {
                                            write-verbose "Error for $srv`:$port`: $_"
                                            $false
                                        }
                                        $tcpclient.Close()
                                    }
                                }
                            }

                            process
                            {
                                foreach($name in $computername)
                                {
	                                $dt = $cdt= Get-Date
	                                Write-verbose "Testing: $Name"
	                                $failed = 0
	                                try{
	                                    $DNSEntity = [Net.Dns]::GetHostEntry($name)
	                                    $domain = ($DNSEntity.hostname).replace("$name.","")
	                                    $ips = $DNSEntity.AddressList | %{
                                            if(-not ( -not $IPV6 -and $_.AddressFamily -like "InterNetworkV6" ))
                                            {
                                                $_.IPAddressToString
                                            }
                                        }
	                                }
	                                catch
	                                {
		                                $rst = New-Object -TypeName PSObject -Property $Hash | Select -Property $props
		                                $rst.name = $name
		                                $results += $rst
		                                $failed = 1
	                                }
	                                Write-verbose "DNS:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
	                                if($failed -eq 0){
	                                    foreach($ip in $ips)
	                                    {
	    
		                                    $rst = New-Object -TypeName PSObject -Property $Hash | Select -Property $props
	                                        $rst.name = $name
		                                    $rst.ip = $ip
		                                    $rst.domain = $domain
		            
                                            if($RDP -or $All)
                                            {
                                                ####RDP Check (firewall may block rest so do before ping
		                                        try{
                                                    $socket = New-Object Net.Sockets.TcpClient($name, 3389) -ErrorAction stop
		                                            if($socket -eq $null)
		                                            {
			                                            $rst.RDP = $false
		                                            }
		                                            else
		                                            {
			                                            $rst.RDP = $true
			                                            $socket.close()
		                                            }
                                                }
                                                catch
                                                {
                                                    $rst.RDP = $false
                                                    Write-Verbose "Error testing RDP: $_"
                                                }
                                            }
		                                Write-verbose "RDP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                        #########ping
	                                    if(test-connection $ip -count 2 -Quiet)
	                                    {
	                                        Write-verbose "PING:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
			                                $rst.ping = $true
			    
                                            if($WSMAN -or $All)
                                            {
                                                try{############wsman
				                                    Test-WSMan $ip -ErrorAction stop | Out-Null
				                                    $rst.WSMAN = $true
				                                }
			                                    catch
				                                {
                                                    $rst.WSMAN = $false
                                                    Write-Verbose "Error testing WSMAN: $_"
                                                }
				                                Write-verbose "WSMAN:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
			                                    if($rst.WSMAN -and $credssp) ########### credssp
			                                    {
				                                    try{
					                                    Test-WSMan $ip -Authentication Credssp -Credential $cred -ErrorAction stop
					                                    $rst.CredSSP = $true
					                                }
				                                    catch
					                                {
                                                        $rst.CredSSP = $false
                                                        Write-Verbose "Error testing CredSSP: $_"
                                                    }
				                                    Write-verbose "CredSSP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
			                                    }
                                            }
                                            if($RemoteReg -or $All)
                                            {
			                                    try ########remote reg
			                                    {
				                                    [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $ip) | Out-Null
				                                    $rst.remotereg = $true
			                                    }
			                                    catch
				                                {
                                                    $rst.remotereg = $false
                                                    Write-Verbose "Error testing RemoteRegistry: $_"
                                                }
			                                    Write-verbose "remote reg:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                            }
                                            if($RPC -or $All)
                                            {
			                                    try ######### wmi
			                                    {	
				                                    $w = [wmi] ''
				                                    $w.psbase.options.timeout = 15000000
				                                    $w.path = "\\$Name\root\cimv2:Win32_ComputerSystem.Name='$Name'"
				                                    $w | select none | Out-Null
				                                    $rst.RPC = $true
			                                    }
			                                    catch
				                                {
                                                    $rst.rpc = $false
                                                    Write-Verbose "Error testing WMI/RPC: $_"
                                                }
			                                    Write-verbose "WMI/RPC:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
                                            }
                                            if($SMB -or $All)
                                            {

                                                #Use set location and resulting errors.  push and pop current location
                    	                        try ######### C$
			                                    {	
                                                    $path = "\\$name\c$"
				                                    Push-Location -Path $path -ErrorAction stop
				                                    $rst.SMB = $true
                                                    Pop-Location
			                                    }
			                                    catch
				                                {
                                                    $rst.SMB = $false
                                                    Write-Verbose "Error testing SMB: $_"
                                                }
			                                    Write-verbose "SMB:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"

                                            }
	                                    }
		                                else
		                                {
			                                $rst.ping = $false
			                                $rst.wsman = $false
			                                $rst.credssp = $false
			                                $rst.remotereg = $false
			                                $rst.rpc = $false
                                            $rst.smb = $false
		                                }
		                                $results += $rst	
	                                }
                                }
	                            Write-Verbose "Time for $($Name): $((New-TimeSpan $cdt ($dt)).totalseconds)"
	                            Write-Verbose "----------------------------"
                                }
                            }
                            end
                            {
	                            Write-Verbose "Time for all: $((New-TimeSpan $total ($dt)).totalseconds)"
	                            Write-Verbose "----------------------------"
                                return $results
                            }
                        }
                    
                    #Build up parameters for Test-Server and run it
                        $TestServerParams = @{
                            ComputerName = $Computer
                            ErrorAction = "Stop"
                        }

                        if($detail -eq "*"){
                            $detail = "WSMan","RemoteReg","RPC","RDP","SMB" 
                        }

                        $detail | Select -Unique | Foreach-Object { $TestServerParams.add($_,$True) }
                        Test-Server @TestServerParams | Select -Property $( "Name", "IP", "Domain", "Ping" + $detail )
                }
                Catch
                {
                    Write-Warning "Error with Test-Server: $_"
                }
            }
            #We just want ping output
            else
            {
                Try
                {
                    #Pick out a few properties, add a status label.  If quiet output, just return the address
                    $result = $null
                    if( $result = @( Test-Connection -ComputerName $computer -Count 2 -erroraction Stop ) )
                    {
                        $Output = $result | Select -first 1 -Property Address,
                                                                      IPV4Address,
                                                                      IPV6Address,
                                                                      ResponseTime,
                                                                      @{ label = "STATUS"; expression = {"Responding"} }

                        if( $quiet )
                        {
                            $Output.address
                        }
                        else
                        {
                            $Output
                        }
                    }
                }
                Catch
                {
                    if(-not $quiet)
                    {
                        #Ping failed.  I'm likely making inappropriate assumptions here, let me know if this is the case : )
                        if($_ -match "No such host is known")
                        {
                            $status = "Unknown host"
                        }
                        elseif($_ -match "Error due to lack of resources")
                        {
                            $status = "No Response"
                        }
                        else
                        {
                            $status = "Error: $_"
                        }

                        "" | Select -Property @{ label = "Address"; expression = {$computer} },
                                              IPV4Address,
                                              IPV6Address,
                                              ResponseTime,
                                              @{ label = "STATUS"; expression = {$status} }
                    }
                }
            }
        }
    }
}
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

#Start the node backend automatically, restarts it if already running
Get-Process | where {$_.name -like "app"} | Stop-Process
cd "$PSScriptRoot/api"
Start-Process -FilePath "$PSScriptRoot/api/app.exe"

#Begins sending out the remote jobs using the local computer for the outputURI
$computername = $env:COMPUTERNAME
Send-Job -computerOU "OU=McConnell AFB Computers,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" -outputURI ("http://$computername" + ":8081/write")

#Small scriptblock to get the number of running jobs left. 
#Clear-Host;((Get-Job -state running) | Measure-Object).count | Write-Host

#Example syntax for Get-Report
#Get-Report -jsonDir "C:\Strom\GitHub\AF-NCC-Scripts\last_logon\Data" -exportCSV C:/strom/LastLogon/report.csv -base "McConnell AFB" -UsersOU "OU=McConnell AFB Users,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL" -ComputersOU "OU=McConnell AFB Computers,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL"


