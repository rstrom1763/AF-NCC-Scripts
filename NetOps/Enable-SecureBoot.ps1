Connection-Test #Depends on additional scripts "Connection-Test", and "Invoke-Ping"

$computers = Get-Content "INSERT FILE PATH HERE" 
#Insert path to text file containing all of the computers to be targeted. 
$notDone = "INSERT FILE PATH HERE"
#Path to text file to append computer names that threw an error
$requiresReboot = "INSERT FILE PATH HERE"
#Computers that were succesful and needing to be rebooted. 

if((Test-Path $notDone) -eq $true){

    Clear-Item $notDone

}

if((Test-Path $requiresReboot) -eq $true){

    Clear-Item $requiresReboot

}

if((Test-Path $notDone) -eq $false){

    New-Item $notDone

}

if((Test-Path $requiresReboot) -eq $false){

    New-Item $requiresReboot

}

$scriptblock = {
     
    Function Bios-config-Lenovo {

<#
.SYNOPSIS
    Modify Lenovo BIOS from within Windows through WMI
.DESCRIPTION
    This script enables the ability to modify the BIOS of a Lenovo computer. if the script is run on a non-Lenovo computer, the script will exit. The script requires local administrative rights to run.
    The script will log its actions to c:\Windows\Config-LenovoBIOS.log. (x:\Windows\Config-LenovoBIOS.log if run in WindowsPE before Windows has been installed)
    
.EXAMPLES
    .\LenovoBIOSManagement.ps1 -EnablePrebootThunderbolt (Enables the ThunderBolt/USB-C port during preboot. Useful if the computer is attached to a Thunderbolt dock, with keyboard attached

    .\LenovoBIOSManagement.ps1 -EnableSecureBoot -Restart (Enables SecureBoot in BIOS and restarts the computer)

    .\LenovoBIOSManagement.ps1 -SupervisorPass christmas -EnableWirelessAutoDisconnection (passing on the Supervisor password and enableds WirelessAutoDisconnection
 
.NOTES
    FileName:    LenovoBIOSManagement.ps1
    Author:      Martin Bengtsson
    Created:     20-08-2017
    Version:     1.0 - (20-08-2017)
    Version:     2.0 - (25-09-2018)
   
    Version history:
    1.0 - (20-08-2017) Script created
    2.0 - (25-09-2018) Script updated with more functionality. Added support for passing on a supervisor BIOS password using the -SupervisorPass parameter. 
                       Also added support for enabling/disabling: OnByAcAttach and WirelessAutoDisconnection
#>

# Define parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
	[string]$SupervisorPass,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableVirtualization,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableVirtualization,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableSecureBoot,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableSecureBoot,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnablePrebootThunderbolt,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisablePrebootThunderbolt,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableTPM,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableTPM,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableAMT,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableAMT,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableOnByAcAttach,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableOnByAcAttach,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EnableWirelessAutoDisconnection,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DisableWirelessAutoDisconnection,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$Restart
)

# Check for administrative rights
if (-Not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    
    Write-Error -Message "The script requires elevation" ; break
    
}

# Create Write-Log function
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,
        
        # EDIT with your location for the local log file
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path="$env:SystemRoot\" + "Config-LenovoBIOS.log",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # if the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # if attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

# Check if Lenovo computer. if not, stop script
$IsLenovo = Get-WmiObject Win32_ComputerSystemProduct | Select-Object Vendor

if ($IsLenovo.Vendor -ne "LENOVO") {
    
    Write-Log -Message "Not a Lenovo laptop - exiting script" ; break
}

else {

    if ($PSBoundParameters["SupervisorPass"]) {

        $Encoding = ",ascii,us"
        $Password1 = "," + "$SupervisorPass" + "$Encoding"
        $Password2 = $SupervisorPass + $Encoding
                        
        $TestingPassword = ((Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2)).return

        if ($TestingPassword -eq "Success") {

            Write-Log -Message "Supervisor password entry succeeded"
        
        }
        else {
            
            Write-Log -Message "Password is incorrect! Please provide the correct supervisor password. Your entry was: $SuperVisorPass" ; break

        }
    }

    else {
        
        # Setting dummy passwords. If no supervisor password is configured, Lenovo allows using any entry (apparently).
        Write-Log -Message "No supervisor password specified. Continuing script using a blank password"
        $Password1 = $null
        $Password2 = $null
    }
    
    # Virtualization, Enable
    if ($PSBoundParameters["EnableVirtualization"]) {
    
        # Getting information for Virtualization in BIOS. Output to variable
        $Virtualization = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "Virtualization*"} | Select-Object CurrentSetting
        $VirtualizationName = $Virtualization.CurrentSetting -split(',')
        $Name = $VirtualizationName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            # if virtualization is disabled, try to enable virtualization
            if ($Virtualization.CurrentSetting -eq "VirtualizationTechnology,Disable"){
    
                Write-Log -Message "$Name disabled - trying to enable" 
            
                # trying to modify the BIOS through calls to WMI. Also saving the settings in BIOS
                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("VirtualizationTechnology,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
            # if already enabled, do nothing
            elseif ($Virtualization.CurrentSetting -eq "VirtualizationTechnology,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # Virtualization, Disable    
    if ($PSBoundParameters["DisableVirtualization"]) {
    
        $Virtualization = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "Virtualization*"} | Select-Object CurrentSetting
        $VirtualizationName = $Virtualization.CurrentSetting -split(',')
        $Name = $VirtualizationName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($Virtualization.CurrentSetting -eq "VirtualizationTechnology,Enable"){
    
                Write-Log -Message "$Name enabled - trying to disable"
    
                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("VirtualizationTechnology,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
            
            elseif ($Virtualization.CurrentSetting -eq "VirtualizationTechnology,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    # SecureBoot, Enable
    if ($PSBoundParameters["EnableSecureBoot"]) {

        $SecureBoot = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "SecureBoot*"} | Select-Object CurrentSetting
        $SecureBootName = $SecureBoot.CurrentSetting -split(',')
        $Name = $SecureBootName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($SecureBoot.CurrentSetting -eq "SecureBoot,Disable") {

                Write-Log -Message "$Name disabled - trying to enable" 

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("SecureBoot,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($SecureBoot.CurrentSetting -eq "SecureBoot,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # SecureBoot, Disable
    if ($PSBoundParameters["DisableSecureBoot"]) {
    
        $SecureBoot = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "SecureBoot*"} | Select-Object CurrentSetting
        $SecureBootName = $SecureBoot.CurrentSetting -split(',')
        $Name = $SecureBootName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($SecureBoot.CurrentSetting -eq "SecureBoot,Enable") {
            
                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("SecureBoot,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
        
            }

            elseif ($SecureBoot.CurrentSetting -eq "SecureBoot,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    # PreBootForThunderboltDevice, Enable
    if ($PSBoundParameters["EnablePrebootThunderbolt"]) {

        $PrebootDevice = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "PreBootForThunderboltDevice"} | Select-Object CurrentSetting
        $PrebootDeviceName = $PrebootDevice.CurrentSetting -split(',')
        $Name = $PrebootDeviceName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($PrebootDevice.CurrentSetting -eq "PreBootForThunderboltDevice,Disable") {

                Write-Log -Message "$Name disabled - trying to enable" 

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("PreBootForThunderboltDevice,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($PrebootDevice.CurrentSetting -eq "PreBootForThunderboltDevice,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # PreBootForThunderboltDevice, Disable
    if ($PSBoundParameters["DisablePrebootThunderbolt"]) {

        $PrebootDevice = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "PreBootForThunderboltDevice"} | Select-Object CurrentSetting
        $PrebootDeviceName = $PrebootDevice.CurrentSetting -split(',')
        $Name = $PrebootDeviceName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($PrebootDevice.CurrentSetting -eq "PreBootForThunderboltDevice,Enable") {

                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("PreBootForThunderboltDevice,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
         
            elseif ($PrebootDevice.CurrentSetting -eq "PreBootForThunderboltDevice,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    # TPM (SecurityChip), Enable
    if ($PSBoundParameters["EnableTPM"]) {

        $TPM = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "SecurityChip"} | Select-Object CurrentSetting
        $TPMName = $TPM.CurrentSetting -split(',')
        $Name = $TPMName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
    
            if ($TPM.CurrentSetting -eq "SecurityChip,Disable") {

                Write-Log -Message "$Name disabled - trying to activate" 

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("SecurityChip,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($TPM.CurrentSetting -eq "SecurityChip,Active") {
                Write-Log -Message "$Name already active - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # TPM (SecurityChip), Disable
    if ($PSBoundParameters["DisableTPM"]) {
        
        $TPM = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "SecurityChip"} | Select-Object CurrentSetting
        $TPMName = $TPM.CurrentSetting -split(',')
        $Name = $TPMName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
            
            if ($TPM.CurrentSetting -eq "SecurityChip,Enable") {

                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("SecurityChip,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
         
            elseif ($TPM.CurrentSetting -eq "SecurityChip,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    # AMT, Enable
    if ($PSBoundParameters["EnableAMT"]) {

        $AMT = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "AMTControl"} | Select-Object CurrentSetting
        $AMTName = $AMT.CurrentSetting -split(',')
        $Name = $AMTName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
    
            if ($AMT.CurrentSetting -eq "AMTControl,Disable") {

                Write-Log -Message "$Name disabled - trying to enable" 

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("AMTControl,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($AMT.CurrentSetting -eq "AMTControl,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # AMT, Disable
    if ($PSBoundParameters["DisableAMT"]) {
        
        $AMT = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "AMTControl"} | Select-Object CurrentSetting
        $AMTName = $AMT.CurrentSetting -split(',')
        $Name = $AMTName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
            
            if ($AMT.CurrentSetting -eq "AMTControl,Enable") {

                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("AMTControl,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
         
            elseif ($AMT.CurrentSetting -eq "AMTControl,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }


    # OnByAcAttach, Enable
    if ($PSBoundParameters["EnableOnByAcAttach"]) {

        $OnByAcAttach = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "OnByAcAttach"} | Select-Object CurrentSetting
        $OnByAcAttachName = $OnByAcAttach.CurrentSetting -split(',')
        $Name = $OnByAcAttachName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($OnByAcAttach.CurrentSetting -eq "OnByAcAttach,Disable") {
                
                Write-Log -Message "$Name disabled - trying to enable"              

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("OnByAcAttach,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($OnByAcAttach.CurrentSetting -eq "OnByAcAttach,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # OnByAcAttach, Disable
    if ($PSBoundParameters["DisableOnByAcAttach"]) {

        $OnByAcAttach = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "OnByAcAttach"} | Select-Object CurrentSetting
        $OnByAcAttachName = $OnByAcAttach.CurrentSetting -split(',')
        $Name = $OnByAcAttachName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
    
            if ($OnByAcAttach.CurrentSetting -eq "OnByAcAttach,Enable") {

                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("OnByAcAttach,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
            
            elseif ($OnByAcAttach.CurrentSetting -eq "OnByAcAttach,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    # WirelessAutoDisconnection, Enable
    if ($PSBoundParameters["EnableWirelessAutoDisconnection"]) {

        $WirelessAutoDisconnection = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "WirelessAutoDisconnection"} | Select-Object CurrentSetting
        $WirelessAutoDisconnectionName = $WirelessAutoDisconnection.CurrentSetting -split(',')
        $Name = $WirelessAutoDisconnectionName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"

            if ($WirelessAutoDisconnection.CurrentSetting -eq "$Name,Disable") {
                
                Write-Log -Message "$Name disabled - trying to enable"              

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$Name,Enable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while enabling $Name in the BIOS"
                    }
            }
         
            elseif ($WirelessAutoDisconnection.CurrentSetting -eq "$Name,Enable") {
                Write-Log -Message "$Name already enabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully enabled"
                }
            
            else { }

    }

    # WirelessAutoDisconnection, Disable
    if ($PSBoundParameters["DisableWirelessAutoDisconnection"]) {

        $WirelessAutoDisconnection = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "WirelessAutoDisconnection"} | Select-Object CurrentSetting
        $WirelessAutoDisconnectionName = $WirelessAutoDisconnection.CurrentSetting -split(',')
        $Name = $WirelessAutoDisconnectionName[0]
        Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
    
            if ($WirelessAutoDisconnection.CurrentSetting -eq "$Name,Enable") {

                Write-Log -Message "$Name enabled - trying to disable"

                try {
                    $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$Name,Disable$Password1").return
                    $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings($Password2).return
                    }
                catch {
                    Write-Log -Message "An error occured while disabling $Name in the BIOS"
                    }
            }
            
            elseif ($WirelessAutoDisconnection.CurrentSetting -eq "$Name,Disable") {
                Write-Log -Message "$Name already disabled - doing nothing"
                }

            if ($Invocation -eq "Success") {
                Write-Log -Message "$Name was successfully disabled"
                }
            
            else { }

    }

    
    # Restart computer
    if ($PSBoundParameters["Restart"]) {
    
        Write-Log -Message "Rebooting the computer"
        Restart-Computer -Force

    }

}

#Getting all Lenovo BiosSettings
#Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | select currentsetting

}

    Function HP-secure-boot{    
[CmdletBinding()]
param (

    [Parameter(Mandatory)]
    [string[]]
    $ComputerName
)

# Scriptblock for Invoke-Command
$InvokeCommandScriptBlock = {
    
    Write-Verbose "Enabling Secure Boot on $env:COMPUTERNAME." -Verbose

    $BiosSettings = Get-WmiObject -Namespace root/hp/instrumentedBIOS -Class HP_BiosEnumeration

    $BiosPassword = 'password'
    $BiosPassword_UTF = "<utf-16/>$BiosPassword"
    $Bios = Get-WmiObject -Namespace root\HP\InstrumentedBIOS -Class HP_BiosSettingInterface

    if ($BiosSettings | Where-Object PossibleValues -Contains 'Legacy Support Disable and Secure Boot Enable') {

        [void]$Bios.SetBiosSetting('Configure Legacy Support and Secure Boot', 'Legacy Support Disable and Secure Boot Enable', $BiosPassword_UTF)
        [void]$Bios.SetBiosSetting('Legacy Boot Options', 'Disable', $BiosPassword_UTF)
        [void]$Bios.SetBiosSetting('UEFI Boot Options', 'Enable', $BiosPassword_UTF)
    }

    if ($BiosSettings | Where-Object PossibleValues -Contains 'Disable Legacy Support and Enable Secure Boot') {

        [void]$Bios.SetBiosSetting('Configure Legacy Support and Secure Boot', 'Disable Legacy Support and Enable Secure Boot', $BiosPassword_UTF)
        [void]$Bios.SetBiosSetting('Legacy Boot Options', 'Disable', $BiosPassword_UTF)
        [void]$Bios.SetBiosSetting('UEFI Boot Options', 'Enable', $BiosPassword_UTF)
    }

    if ($BiosSettings | Where-Object Name -eq 'Legacy Support') {

        [void]$Bios.SetBiosSetting('Legacy Support', 'Disable', $BiosPassword_UTF)
    }

    if ($BiosSettings | Where-Object Name -eq 'Secure Boot') {

        [void]$Bios.SetBiosSetting('Secure Boot', 'Enable', $BiosPassword_UTF)
    }

    if ($BiosSettings | Where-Object Name -eq 'SecureBoot') {

        [void]$Bios.SetBiosSetting('SecureBoot', 'Enable', $BiosPassword_UTF)
    }

    if ($BiosSettings | Where-Object Name -eq 'Boot Mode') {

        [void]$Bios.SetBiosSetting('Boot Mode', 'UEFI Native (Without CSM)', $BiosPassword_UTF)
    }

    # Restart computer if no user logged on
    $Quser = quser.exe 2>$null
    if ($null -eq $Quser) {Restart-Computer -Force}
}

# Parameters for Invoke-Command
$InvokeCommandParams = @{

    ComputerName = $ComputerName
    ScriptBlock = $InvokeCommandScriptBlock
    ErrorAction = $ErrorActionPreference
}

Invoke-Command @InvokeCommandParams 
}


    
    $make = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer
    
    if($make -eq "Lenovo"){

        Bios-config-Lenovo -SupervisorPass password -EnableSecureBoot
    
    }

    if($make -eq "HP" -or $make -eq "Hewlett-Packard"){
        
        HP-secure-boot -ComputerName $env:COMPUTERNAME
        
    }

}

foreach ($pc in $computers){

    $success = $true
    try{

        Invoke-Command -ComputerName $pc -ScriptBlock $scriptblock

    }
    catch{
    
        Add-Content -Path $notDone -Value $pc
        $success = $false

    }

    if($success){
    
        Add-Content -Path $requiresReboot -Value $pc
    
    }
}
