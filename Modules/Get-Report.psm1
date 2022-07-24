Function Get-Report {

    param(
        [Parameter(Mandatory = $true)][String]$JsonDir,
        [Parameter(Mandatory = $true)][String]$ExportCSV,
        [String]$ADCacheFile,
        [Parameter(Mandatory = $True)][String]$Base,
        [Parameter(Mandatory = $True)][String]$UsersOU,
        [Parameter(Mandatory = $True)][String]$ComputersOU
    )
    
    [string]$date = Get-Date -Format "MM-dd-yyy HH-mm"
    $ExportCSV = $ExportCSV.Insert(($ExportCSV.Length - 4), $date)

    if (Test-Path "C:/adCache.csv") { $defaultADCacheFile = Get-Item "C:/adCache.csv" } else { $defaultADCacheFile = "C:/adCache.csv" }
    $timespan = New-TimeSpan -Days 7

    if ((((Get-ChildItem -Path $JsonDir) | Measure-Object).Count) -eq 0) {
        Write-Error "Json directory is empty."
        return
    }

    foreach ($json in (Get-ChildItem $jsonDir)){
        try {
            (Get-Content $json.fullname | ConvertFrom-Json) > $null
        }
        catch {
            Write-Error "Invalid Json in file: $($json.name)"
            Write-Host (Get-Content $json.fullname)
            Remove-Item -Path $json.fullname -WhatIf
        }
    }
    Get-ChildItem $jsonDir | Get-Content | ConvertFrom-Json | Export-Csv $exportCSV -NoTypeInformation

    if ($adCacheFile -eq "") {
        if ((Test-Path $defaultADCacheFile) -and (((Get-Date) - $defaultADCacheFile.LastWriteTime) -lt $timespan)) {
            $users = Import-Csv $defaultADCacheFile
        }
        else {
            Write-Host "Fetching user data from user AD OU..."
            Get-ADUser -SearchBase $usersOU -Filter '*' -Properties * | Export-Csv $defaultADCacheFile
            $users = Import-Csv $defaultADCacheFile
        }
    }
    elseif (!($adCacheFile -eq "")) {
        if ((Test-Path $adCacheFile) -and ($defaultADCacheFile.LastWriteTime -lt $timespan)) {
            $users = Import-Csv $adCacheFile
        }
        else {
            Write-Host "Fetching user data from user AD OU..."
            Get-ADUser -SearchBase $usersOU -Filter '*' -Properties * | Export-Csv $adCacheFile
            $users = Import-Csv $adCacheFile
        }
    }
    
    $data = Import-Csv $exportCSV

    $totalCount = ($data | Measure-Object).Count
    $count = 1

    foreach ($entry in $data) {

        [int]$complete = ($count / $totalCount) * 100
        Write-Progress -Activity "Cross Referencing with AD" -Status "Status: $complete%: $count out of $totalCount" -PercentComplete $complete

        if ($entry.Username -NotLike "*No user sessions*") {

            $entry.username = $entry.Username -replace "[^0-9]"

        }

        foreach ( $user in $users ) {

            $user.gigID = $user.gigID -replace "[^0-9]"

            if ($entry.Username -eq $user.gigID) {
                
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "User" -Value $user.DisplayName -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "Organization" -Value $user.Organization -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "Office" -Value $user.Office -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "Phone" -Value $user.OfficePhone -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "Email" -Value $user.mail -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "personalTitle" -Value $user.personalTitle -MemberType NoteProperty -ErrorAction SilentlyContinue
                Add-Member -InputObject $data[($data.indexof($entry))] -Name "Title" -Value $user.Title -MemberType NoteProperty -ErrorAction SilentlyContinue

            }

        }
        $count++
    }

    $data | Export-Csv $exportCSV -NoTypeInformation

}