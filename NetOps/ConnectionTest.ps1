
function Connection-Test {

    $InFile = "computers.txt"
    $OutFile = "RequiresPush.txt"
    $FilePath = "C:\Strom"


    $computers = Get-Content "$FilePath\$InFile"
    $Success = "$FilePath\$OutFile"

    # Create Log file and folder
    if (!(Test-Path "$Success")) {
        New-Item -Path "$Success" -ItemType "file" -force
    } 
    else {
        Remove-Item $Success -Force
    }


    $GoodFile = $computers | Invoke-Ping -Quiet
    $GoodFile >> $Success

}