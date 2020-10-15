cls

Connection-Test

$savePath = "C:\Strom\SDC Transcript.csv"
$failureSavePath = "C:\Strom\SDC Transcript Fails.txt"
$computers = Get-Content "C:\Strom\RequiresPush.txt"
$tempFilePath = "C:/SDC.csv"

if ((Test-Path $savePath) -eq $false){

        New-Item -Path $savePath

}

Stop-Job *
Remove-Job *
Clear-Content $savePath
Clear-Content $failureSavePath

function Get-SDC {
    
    Import-Module Microsoft.PowerShell.Management
    $tempFilePath = "C:/SDC.csv"
    $hostname = hostname
    $info = Get-ComputerInfo
    $winversion = $info | select windowsversion
    $buildNumber = $info | select osversion
    $SDC = reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation\ /v Model | 
    Select-String Model
    $SDC = $SDC -replace "Model    REG_SZ",""
    $SDC = $SDC.Trim()
    
    $properties = @{

        hostname = $hostname
        winversion = $winversion.("WindowsVersion")
        buildnumber = $buildNumber.("osversion")
        SDC = $SDC

    }

    
    $output = New-Object psobject -Property $properties;$output

    if ((Test-Path $tempFilePath) -eq $true){

        rm $tempFilePath

    }

    $output | Select-Object hostname,winversion,buildnumber,SDC |  
    Export-Csv -Path $tempFilePath -NoTypeInformation -NoClobber

}

foreach($pc in $computers){

    Invoke-Command -computername $pc ${function:Get-SDC} -AsJob

}

Wait-Job * -Timeout 120

$jobs = Get-Job
$count = 0

foreach ($job in $jobs){

    if($job.("State") -eq "Failed"){

        Remove-Job ($job.("Id"))

    }
}

foreach ($computer in $computers){

    try {

        $filePath = "\\$computer\C$\SDC.csv"
        Import-Csv -Path $filePath | 
        Export-Csv -Path $savePath -Append -NoTypeInformation
        rm $filePath
        Write-Host $computer

        }

    Catch {

        Write-Host $computer "Failed " + $_
        $count = $count + 1
        Add-Content -Value ($computer + " " + $_) -Path $failureSavePath

    }
}

Write-Host "`n$count Computers Failed"

#A1C Strom