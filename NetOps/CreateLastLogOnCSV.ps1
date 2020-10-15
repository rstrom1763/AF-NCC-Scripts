
#Creates a CSV of all of computers on the domain and some information: name, when they were created, location, and last log on


function Get-LastLogon  {

    Param([Parameter(Mandatory=$True)][String]$SaveFolder) #Mandatory parameter that dictates folder to save output csv into

    $SaveFolder = $SaveFolder -replace '"',"" #Ensures that the input does not have double quotes around it that will cause an error

    [string]$date = Get-Date -Format "MM-dd-yyy HH-mm" #Gets the current date
    [string]$outCSV = "$SaveFolder\ComputerLastLogonDate$date.csv" #Creates the output filepath combining save folder and date

    Clear
    Write-Host "Collecting...`n"

    Get-ADComputer -SearchBase 'OU=McConnell AFB Computers,OU=McConnell AFB,OU=AFCONUSWEST,OU=Bases,DC=area52,DC=afnoapps,DC=usaf,DC=mil' -Filter '*' -Properties *  | #Collects computer info from AD
    Select-Object cn,created,IPv4Address,location,LastLogonDate | #Filters out desired objects from the AD info
    Export-Csv $outCSV -Encoding ascii -NoTypeInformation #Exports filtered objects into a csv saved into folder dictated in SaveFolder parameter

    Clear
    Write-Host "Saved to $outCSV`n" -ForegroundColor Green


    <#
    AMN Strom
    February 20th, 2020
    #>

}