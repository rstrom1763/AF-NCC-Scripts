#Designed to create a list of computers that do not have secure boot across the base


cls

Connection-Test

$savePath = "C:\Strom\NoSecureBoot.txt"
$computers = Get-Content "C:\Strom\RequiresPush.txt"

Clear-Content -Path $savePath

Function Check-SecureBoot {

    $tempSavePath = "C://tempfile.txt"

    if ((Test-Path $tempSavePath) -eq $true){

        rm $tempSavePath

    }

    try {
        
        $secureBoot = Confirm-SecureBootUEFI

        }

    Catch {
        
        New-Item -Path $tempSavePath
        Add-Content $tempSavePath -Value $computer
        return

        }

    if ($secureBoot -eq $false){
        
        New-Item $tempSavePath
        Add-Content $tempSavePath -Value $computer

        }
    
}


foreach ($computer in $computers){
    
    Invoke-Command -computername $computer ${function:Check-SecureBoot} -AsJob

}

Wait-Job * -Timeout 120

$jobs = Get-Job

foreach ($job in $jobs){

    if($job.("State") -eq "Failed" ){

        Remove-Job ($job.("Id"))

    }

    if($job.("State") -eq "Running"){
        
        Stop-Job ($job.("Id"))
        Remove-Job ($job.("Id"))

    }
}

if ((Test-Path $savePath) -eq $false){

        New-Item $savePath

    }

Foreach ($computer in $computers){

    $filePath = "\\$computer\C$\tempfile.txt"

    if ((Test-Path $filePath) -eq $true){

        try {

            Add-Content $savePath -value $computer
            rm $filePath
            Write-Host $computer

        }
    
        Catch {

            Write-Host "Something failed, I don't even know man " + $_

        }

    }
    
}

#A1C Strom 9/21/2020