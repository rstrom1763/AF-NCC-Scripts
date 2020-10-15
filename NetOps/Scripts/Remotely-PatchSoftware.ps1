########################################
########################################
########################################
#### CREATED BY: A1C BILLIE GRIFFIN ####
## WITH HELP FROM: MR. CRAIG COURTNEY ##
########################################
########################################
########################################
cls

$Plugin = "RemovePFX"
$INDir = "C:\Users\1086335782C\Desktop"
$INFile = "Good.txt"

$PatchServer = "\\52prpr-fs-001\Patching\Plugins"

$PCs = Get-Content "$INDir\$INFile"

$Computers = $PCs | Invoke-Ping -Quiet

workflow WorkflowPSRemoting {
        param (
            [Parameter (Mandatory = $true)]
            [object[]]$Computers
        )
        $ErrorActionPreference = "SilentlyContinue"

        foreach -parallel -throttlelimit 16 ($Computer in $Computers) { 
            psexec -s -d -n 5 \\$Computer powershell.exe Enable-PSRemoting -force
        }

        $ErrorActionPreference = "Continue"
}

workflow WorkflowCopy {
    param (
         [Parameter (Mandatory = $true)]
         [object[]]$Computers,$Plugin
    )
    foreach -parallel -throttlelimit 16 ($Computer in $Computers) {

        if (!(Test-Path "\\$Vomputer\c$\installfiles\Deploy")) {
            New-Item -Path "\\$Computer\c$\installfiles\Deploy" -ItemType "directory" -force
        }
   
        Remove-Item "\\$Computer\c$\installfiles\Deploy\*" -Recurse -Force

        Copy-Item "$PatchServer\$Plugin\Deploy\*" "\\$Computer\C$\installfiles\Deploy\" -Recurse -Force -ErrorAction SilentlyContinue
        }
}

workflow WorkflowInstallNoCheck {
    param (
         [Parameter (Mandatory = $true)]
         [object[]]$computers
    )
    foreach -parallel -throttlelimit 16 ($computer in $computers) {
        #Invoke-Command -ComputerName $computer -FilePath "\\52prpr-fs-001\Patching\Plugins\RemovePFX\Deploy\install.ps1"
        psexec.exe -s -d \\$computer powershell.exe C:\installfiles\Deploy\install.ps1
    }
}

workflow WorkflowInstallCheck {
    param (
         [Parameter (Mandatory = $true)]
         [object[]]$computers
    )
    foreach -parallel -throttlelimit 16 ($computer in $computers) {
        psexec -s -n 10 \\$computer powershell.exe C:\installfiles\Deploy\install.ps1
    }
}

#####

$Ans = Select-MenuItem -Heading "Enable PSRemoting" -Prompt "Would you like all computers to have PSRemoting enabled?" -MenuText 'yn' -Default "Yes"

if ($Ans -eq "Yes") {

    Write-Host " Enabling some stuff here...." -ForeGroundColor Yellow
    
    WorkflowPSRemoting -Computers $Computers | Out-Null

    Write-Host "Enabled PSRemoting on all computers.`n" -ForegroundColor Green
}

elseif ($Ans -eq "No") { 
    Write-Host "User chose not to run workflow. Continuing script.`n" -ForegroundColor Yellow
}

Write-Host "Copying files over to remote computers...`n" -ForegroundColor Yellow

WorkflowCopy -Computers $Computers -Plugin $Plugin -AsJob | Out-Null

Get-Job | Wait-Job | Out-Null
Get-Job | Remove-Job

$Time = Get-Date -Format G
Write-Host "All files successfully copied over at $Time.`n" -ForegroundColor Green
Write-Host "Starting installation on remote computers.`n" -ForegroundColor Yellow

$Ans2 = Select-MenuItem -Heading "Verify" -Prompt "Would you like to wait to see if all computers successfully installed? If no, $Plugin will still install." -MenuText 'yn' -Default "Yes"

if ($Ans2 -eq "Yes") {
    
    WorkflowInstallCheck -computers $Computers -Force -AsJob | Out-Null

    Write-Host "User chose to verify installation. Please wait for install to finish.`n" -ForegroundColor Yellow

    While (Get-Job -state running) {
        $Time = Get-Date -Format G
        Write-Host "Computer(s) are still installing $Plugin at $Time. Please wait.`n" -ForegroundColor Yellow
        Start-Sleep 1
        cls
    }

    Get-Job | Wait-Job | Out-Null  
    Get-Job | # Remove-Job 

    Write-Host "Installation has completed.`n" -ForegroundColor Green
    Start-Sleep 1 
    Write-Host "Testing to see $Plugin installed correctly..." -ForegroundColor Yellow

    if ($Plugin -eq "AdobeDCUninstaller" -or $Plugin -eq "AcrobatInstaller" -or $Plugin -eq "AcrobatDCInstaller") { $Plugin = "Acrobat" }
    if ($Plugin -eq "JavaUninstall") { $Plugin = "Java" }

    foreach ($computer in $computers) { 
        Invoke-Command -ScriptBlock ${function:get-installedsoftware} -ComputerName $computer -AsJob | Out-Null
    }

    Get-Job | Wait-Job | Out-Null

<#    if (!($Plugin -eq "")) {

        $Software = Get-Job | Receive-Job
        $Programs = $Software | Where {$_.Name -like "*$Plugin*"}
        $Programs = $Programs | Format-Table -Property Name, Version, ComputerName | Out-String

        if ($Programs -eq "") {
            Write-Host "`n$computer does not have $Plugin installed." -foregroundcolor Yellow
        }
        else {
            Write-Host "$Programs" -ForegroundColor Green
        }

    Clear-Variable Software, Programs

    Get-Job | Remove-Job
    }
}

elseif ($Ans2 -eq "No") {

    WorkflowInstallNoCheck -computers $Computers -AsJob | Out-Null

    $Time = Get-Date -Format G
    Write-Host "Script completed at $Time" -ForegroundColor Green

#>
}
