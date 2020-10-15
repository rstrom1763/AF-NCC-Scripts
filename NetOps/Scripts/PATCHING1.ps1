########################################
#### CREATED BY: A1C BILLIE GRIFFIN ####
## WITH HELP FROM: MR. CRAIG COURTNEY ##
########################################

$Plugin = "RemoveFirefox"

#AdobeDCUninstaller,AcrobatInstaller,Acrobat
#Java
#DBsign

#Syntax for $computers is one of the two following

    #For 1-4 computers, use $computers = "PRPRL-Example","PRPRL-Example","PRPRL-Example","PRPRL-Example"
    #For 4+ computers, have $computers point to a filepath. $computers = Get-Content "C:\users\YourProfileHere\Desktop\List.txt"

$computers = Get-Content "C:\Users\1086335782C\Desktop\VLC.txt"
$tempfile = "C:\Users\1086335782C\Desktop\swaplist.txt"
$badboy = "C:\Users\1086335782C\Desktop\badboy.txt"

if (Test-Path "$tempfile") {
    Remove-Item "$tempfile"
    New-Item -ItemType file -Path "$tempfile"
}

if (Test-Path "$badboy") {
    Remove-Item "$badboy"
    New-Item -ItemType File -Path "$badboy"
}

$good = $computers | Invoke-Ping -Quiet
$good >> $tempfile

#Get-Content $tempfile | Out-File $computers -Append

########## You shouldn't need to change anything past this point ########## 

#Required functions for this script to work.

Function Get-InstalledSoftware {
	Param
	(
		[Alias('Computer','ComputerName','HostName')]
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
		[string[]]$Name = $env:COMPUTERNAME
	)
	Begin
	{
		$LMkeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
		$LMtype = [Microsoft.Win32.RegistryHive]::LocalMachine
		$CUkeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
		$CUtype = [Microsoft.Win32.RegistryHive]::CurrentUser
		
	}
	Process
	{
		ForEach($Computer in $Name)
		{
			$MasterKeys = @()
			If(!(Test-Connection -ComputerName $Computer -BufferSize 16 -count 1 -quiet))
			{
				Write-Error -Message "Unable to contact $Computer. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Computer
				Break
			}
			$CURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($CUtype,$computer)
			$LMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($LMtype,$computer)
			ForEach($Key in $LMkeys)
			{
				$RegKey = $LMRegKey.OpenSubkey($key)
				If($RegKey -ne $null)
				{
					ForEach($subName in $RegKey.getsubkeynames())
					{
						foreach($sub in $RegKey.opensubkey($subName))
						{
							$MasterKeys += (New-Object PSObject -Property @{
							"ComputerName" = $Computer
							"Name" = $sub.getvalue("displayname")
							"SystemComponent" = $sub.getvalue("systemcomponent")
							"ParentKeyName" = $sub.getvalue("parentkeyname")
							"Version" = $sub.getvalue("DisplayVersion")
							"UninstallCommand" = $sub.getvalue("UninstallString")
							})
						}
					}
				}
			}
			ForEach($Key in $CUKeys)
			{
				$RegKey = $CURegKey.OpenSubkey($Key)
				If($RegKey -ne $null)
				{
					ForEach($subName in $RegKey.getsubkeynames())
					{
						foreach($sub in $RegKey.opensubkey($subName))
						{
							$MasterKeys += (New-Object PSObject -Property @{
							"ComputerName" = $Computer
							"Name" = $sub.getvalue("displayname")
							"SystemComponent" = $sub.getvalue("systemcomponent")
							"ParentKeyName" = $sub.getvalue("parentkeyname")
							"Version" = $sub.getvalue("DisplayVersion")
							"UninstallCommand" = $sub.getvalue("UninstallString")
							})
						}
					}
				}
			}
			$MasterKeys = ($MasterKeys | Where {$_.Name -ne $Null -AND $_.SystemComponent -ne "1" -AND $_.ParentKeyName -eq $Null} | select Name,Version,ComputerName,UninstallCommand | sort Name)
			$MasterKeys
		}
	}
	End
	{
		
	}
}

FUNCTION GLOBAL:Select-MenuItem {

[CMDLETBINDING()]

PARAM
(

	# a text message that will appear above the prompt string
	[string]
	$heading = "Response required:"
	,
	# a string with which the user will be prompted for input
	[string]
	$Prompt = "Enter your selection from the menu shown below:"
	,
	<#
		the default choice, given in the form in which the chosen item will be returned.
		if no -default parameter is specified, the default is the first item, item zero.
		-1:
			default choice:   - none
			function returns: - the numeric value of the chosen item
		2:
			default choice:   - the third item
			function returns: - the numeric value of the chosen item
		'R':
			default choice:   - the item with 'R' as the accelerator
			function returns: - the accelerator of the chosen item
		'Retry':
			default choice:   - the item with 'Retry' as the keyword
			function returns: - the keyword of the chosen item
	#>
	$Default = 0
	,
	<#
		defines the menu choices available in one of two ways:
			a) menu of options in this format:
				"&Delete = delete file `n &Rename = rename file `n e&Xit = stop":
				==> [D] Delete  [R] Rename  [X] eXit  [?] Help (default is "D"):
			b) or one of these menu shortcuts
				"OK"    ==> [O] Ok  [?] Help
				"OKC"   ==> [O] Ok  [C] Cancel  [?] Help
				"ARI"   ==> [A] Abort  [R] Retry  [I] Ignore  [?] Help
				"YN"    ==> [Y] Yes  [N] No  [?] Help
				"YNC"   ==> [Y] Yes  [N] No  [C] Cancel  [?] Help
				"RC"    ==> [R] Retry  [C] Cancel  [?] Help
				"YANLS" ==> [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help"
	#>
	[string]
	$MenuText = ""
	,
	<#
		menu option delimiter character. The default is the newline character,
		allowing the use of a here-string with one option per line
	#>
	[string]
	$Delimiter = "`n"
	,
	# optionally display the menu with help text before prompting for the user's choice
	[switch]
	$showMenu

)

	# expand an option menu shortcut to a full option menu
	switch ( $MenuText ) {

		"Ok"    { $MenuText = "&Ok = acknowledge the above information" }

		"OkC"   { $MenuText = "&Ok = perform the suggested action $Delimiter "+`
		                      "&Cancel = cancel the current operation" }

		"ARI"   { $MenuText = "&Abort = abort the current operation $Delimiter "+`
		                      "&Retry = retry the action that failed $Delimiter "+`
		                      "&Ignore = ignore the error and continue" }

		"YN"    { $MenuText = "&Yes = perform the suggested action $Delimiter "+`
		                      "&No = do not perform the suggested action" }

		"YNC"   { $MenuText = "&Yes = perform the suggested action $Delimiter "+`
		                      "&No = do not perform the suggested action $Delimiter "+`
		                      "&Cancel = cancel the current operation altogether" }

		"RC"    { $MenuText = "&Retry = retry the action that failed $Delimiter "+`
		                      "&Cancel = cancel the current operation altogether" }

		"YANLS" { $MenuText = "&Yes = Continue with only the next step of the operation. $Delimiter"+`
							  "Yes to &All  = Continue with all the steps of the operation. $Delimiter"+`
							  "&No          = Skip this operation and proceed with the next operation. $Delimiter"+`
							  "No to A&ll   = Skip this operation and all subsequent operations. $Delimiter"+`
							  "&Suspend     = Pause the current pipeline and return to the command prompt. Type 'exit' to resume the pipeline." }

		""     {

			# Special case, an empty -MenuText value shows all available shortcuts
			$Heading   = "Demonstration mode: the available menu shortcuts are shown as"
			$Prompt    = "keywords with the corresponding options listed under 'Meaning'"
			$Default   = "OK"
			$showMenu  = $true 
			$MenuText  = @"
				&OK    = OK only
				OK&C   = OK and Cancel
				AR&I   = Abort, Retry and Ignore
				&YN    = Yes and No
				Y&NC   = Yes, No, and Cancel
				&RC    = Retry and Cancel
				Y&ANLS = Yes, Yes to All, No, No to All, Suspend
"@
		}
	}
	
	# set return format and default value to use assuming a numeric -default value
	$returnFormat = "number"
	$useAsDefault = $default

	# create arrays for accumulating various values for each menu option:
	$choices      = @() # ChoiceDescription object
	$accelerators = @() # accelerator characters
	$keyWords     = @() # keyword
	$menushow     = @() # menu option representation for -showMenu switch

	# process the menu of options
	foreach ( $item in $MenuText.split( $Delimiter ) ) {

		# get the current menu item index
		$itemNo = $choices.count

		# extract menu item components
		$keyword,$phrase = $item.split("=")
		$keyword         = $keyword.trim()
		$phrase          = $phrase.trim()
		$word            = $keyword.replace("&","")
		$before,$after   = $keyword.split("&")

		# extract the accelerator
		TRY {$accelerator = $after[0]} CATCH {$accelerator = "$itemNo"}
		
		# set the return format and numeric default value to use on a match of the accelerator or keyword
		if ( $accelerator -eq $default ) {
			# accelerator mode
			$returnFormat = "keyChar"
			$useAsDefault = $itemNo
		} elseif ( $word -eq $default ) {
			# word mode
			$returnFormat = "keyWord"
			$useAsDefault = $itemNo
		}

		# accumulate assorted data onto arrays
		$choices      += New-Object System.Management.Automation.Host.ChoiceDescription $keyword, $phrase
		$accelerators += $accelerator
		$keyWords     += $word
		$menushow     += "$word`t - $phrase"

	}

	# build an options object from the accumulated choices	
	$options = [System.Management.Automation.Host.ChoiceDescription[]]( $choices )

	# optionally display the menu first
	if ( $showMenu ) {
		write-host "`n$Heading`n$Prompt`n`nKeyword`t - Meaning"
		write-host '=================================================='
		$menushow | foreach {write-host $_}
		write-host '=================================================='
	}

	TRY
	{
		# invoke the PromptForChoice method with indictated parameters
		$result = $host.ui.PromptForChoice( $heading, $Prompt, $options, $useAsDefault )
	}
	CATCH
	{
		# assume failure resulted from an invalid default parameter, and retry with no default
		$result = $host.ui.PromptForChoice( $heading, $Prompt, $options, -1 )
	} 
	
	# substitute return value of a different type if indicated by the default parameter
	switch ( $returnFormat ) {
		"keychar" { $result = $accelerators[$result] }
		"keyword" { $result = $keyWords[$result] }
	}

	# return the result to the function caller
	return $result
}

#Gets the online systems rather than the entire list from Computers text file
$computers = Get-Content "C:\Users\1086335782C\Desktop\swapfile.txt"

#Popup to ask user if they would like to enable PSRemoting on all computers in the script file. Highly recommended to select 'Yes' unless you know all computers have it enabled already.
$Ans = select-menuitem -heading "ENABLE PSREMOTING" -prompt "Would you like all computers to have PSRemoting enabled?" -menutext 'yn' -default "Yes"

#If user selected 'Yes', the PSRemoting workflow will run.
if ($Ans -eq "Yes") {

    $ErrorActionPreference = "Ignore"

    workflow PSRemoting {
        param (
             [Parameter (Mandatory = $true)]
             [object[]]$computers
        )
        foreach -parallel -throttlelimit 16 ($computer in $computers) {
            if(Test-Connection -ComputerName $computer -BufferSize 16 -Count 1 -Quiet) {
                psexec -s -d \\$computer powershell.exe Enable-PSRemoting -force
            }
            else {
                "$computer is offline"
            }
        }
    }

    PSRemoting -computers $Computers

    $ErrorActionPreference = "Continue"

    Write-Host "Enabled PSRemoting on all computers." -ForegroundColor Green

    Write-Host ""
}
    else {
        Write-Host "User chose not to run workflow. Continuing script.`n" -ForegroundColor Yellow
    }

    #This copies the required setup files to selected machines.
    foreach ($computer in $computers) {
        $Time = Get-Date -Format G
        if (!(Test-Connection $computer -BufferSize 16 -Count 1 -Quiet)) {
            $Time = Get-Date -Format G
            Write-Host "$computer not connected at $Time" -ForeGroundColor red
        }
        else {
            if (!(Test-Path "\\$computer\c$\installfiles\Deploy")) {
                New-Item -Path "\\$computer\c$\installfiles\Deploy" -ItemType "directory" -force
            }
        Remove-Item "\\$computer\c$\installfiles\Deploy\*" -Recurse -Force
        Start-Sleep 2
        $source = "\\52prpr-fs-001\Patching\Plugins\$Plugin\Deploy\*"
        $destination = "\\$computer\C$\installfiles\Deploy\"
        Start-Job {Copy-Item $args[0] $args[1] -recurse -force -ErrorAction SilentlyContinue} -ArgumentList $source,$destination | Out-Null
        $Time = Get-Date -Format G
        Write-Host "Started copying files to $Computer at $Time" -ForegroundColor Yellow
        }
    } 

    Write-Host "===============================================================" -ForegroundColor Red

    #This waits until all computers have finished copying the files.
    Get-Job | Wait-Job | Out-Null

    #Just some nice output.
    $Time = Get-Date -Format G
    Write-Host "All files successfully copied over at $Time.`n" -ForegroundColor Green
    Write-Host "Craig's script has completed. Moving on to Griffin's script,`nwhich installs Craig's script plugins.`n" -ForegroundColor White

    #This removes all prior jobs. Just some cleaning.
    Get-Job | Remove-Job

    #This is what actually runs the install.ps1 on the machine. This part takes a while.
    foreach ($computer in $computers) {
        if (Test-Connection -ComputerName $computer -BufferSize 16 -Count 1 -Quiet) {
            Invoke-Command -ComputerName $computer -ScriptBlock {C:\installfiles\Deploy\install.ps1} -AsJob | Out-Null
            $Time = Get-Date -Format G
        }
    }

    Write-Host "install.ps1 ($Plugin) has started on all computers at $Time`n" -foregroundcolor Green

    #This waits until all computers have completed before moving onto the next part.
    Get-Job | Wait-Job | Out-Null

    #Just some nice output
    $Time = Get-Date -Format G
    Write-Host "$Plugin completed at $Time" -ForegroundColor Green
    Write-Host "Testing to see $Plugin installed correctly..." -ForegroundColor Yellow

    #This changes the Plugin variable to Acrobat, so when the Get-Installed Software function queries the machine, it actually returns output.
    If ($Plugin -eq "AdobeDCUninstaller" -or $Plugin -eq "AcrobatInstaller") {
        $Plugin = "Acrobat"
    }

    #This runs the Get-Installed Software function
    foreach($computer in $computers) {
        if (!(Test-Connection -ComputerName $computer -Count 1 -BufferSize 16 -Quiet)) {
            Write-Host "$computer is offline" -ForegroundColor Red
        }
        else {
            Invoke-Command -ScriptBlock ${function:get-installedsoftware} -ComputerName $computer -AsJob | Out-Null
        }
}

#This waits until all computers have completed before moving onto the next part.
Get-Job | Wait-Job | Out-Null

#This receives the jobs and does some formatting before outputting result to host.
if (!($Plugin -eq "")) {
    $Software = Get-Job | Receive-Job
    $Programs = $Software | Where {$_.Name -like "*$Plugin*"}
    $Programs = $Programs | Format-Table -Property Name, Version, ComputerName | Out-String
    
    if ($Programs -eq "") {
        Write-Host "$computer does not have $Plugin installed." -foregroundcolor Yellow
    } 
    else {
        Write-Host "$Programs" -ForegroundColor Green
    }
    Clear-Variable Software, Programs
    Get-Job | Remove-Job
}