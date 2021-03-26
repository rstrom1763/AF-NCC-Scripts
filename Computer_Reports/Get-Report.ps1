Function Get-Report {

    param(
        [Parameter(Mandatory = $true)][String]$jsonDir,
        [Parameter(Mandatory = $true)][String]$exportCSV,
        [String]$adCacheFile,
        [Parameter(Mandatory=$True)][String]$base
    )
    
    $domain = Get-ADOrganizationalUnit -filter * | Where-Object { $_.distinguishedname -like "*user*" -and $_.distinguishedname -notcontains "*fn*" } | Select-String $base | select-string "afb users"
    if (Test-Path "C:/adCache.csv") { $defaultADCacheFile = Get-Item "C:/adCache.csv" } else { $defaultADCacheFile = "C:/adCache.csv" }
    $timespan = New-TimeSpan -Days 14

    Get-ChildItem $jsonDir | Get-Content | ConvertFrom-Json | Select-Object ComputerName, IP, Username, LogonTime, SDC, Make, Model, BIOS, SecureBoot | Export-Csv $exportCSV -NoTypeInformation

    if ($adCacheFile -eq "") {
        if (Test-Path $defaultADCacheFile -and ($defaultADCacheFile.LastWriteTime -lt $timespan)) {
            $users = Import-Csv $defaultADCacheFile
        }
        else {
            Get-ADUser -SearchBase $domain -Filter '*' -Properties * | Export-Csv $defaultADCacheFile
            $users = Import-Csv $adCacheFile
        }
    }
    elseif (!$adCacheFile -eq "") {
        if ((Test-Path $adCacheFile) -and ($defaultADCacheFile.LastWriteTime -lt $timespan)) {
            $users = Import-Csv $adCacheFile
        }
        else {
            Get-ADUser -SearchBase $domain -Filter '*' -Properties * | Export-Csv $adCacheFile
            $users = Import-Csv $adCacheFile
        }
    }
    
    $data = Import-Csv $exportCSV

    foreach ($entry in $data) {

        if ($entry.Username -NotLike "*No user sessions*") {

            $entry.username = $entry.Username -replace "[^0-9]"

        }

        foreach ( $user in $users ) {

        
            if ($user.gigID -NotLike "*No user sessions*") {

                $user.gigID = $user.gigID -replace "[^0-9]"

            }

            try {
            
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
            Catch {

                if ($entry.Username -eq $user.gigID) {
                    
                    Add-Member -InputObject $data -Name "User" -Value $user.DisplayName -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "Organization" -Value $user.Organization -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "Office" -Value $user.Office -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "Phone" -Value $user.OfficePhone -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "Email" -Value $user.mail -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "personalTitle" -Value $user.personalTitle -MemberType NoteProperty -ErrorAction SilentlyContinue
                    Add-Member -InputObject $data -Name "Title" -Value $user.Title -MemberType NoteProperty -ErrorAction SilentlyContinue
        
                }

            }

        }

    }

    $data | Export-Csv $exportCSV -NoTypeInformation

}