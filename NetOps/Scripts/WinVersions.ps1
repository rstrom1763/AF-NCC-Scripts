$InFile = "computers.txt"
$OutFile = "Winvers.txt"
$FilePath = "C:\Transfer\PSScripts"

$Computername = Get-Content "$FilePath\$InFile"

    Foreach ($Computer in $ComputerName)
    {
        $Code = {
            $ProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
            Try
            {
                $Version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
            }
            Catch
            {
                $Version = "N/A"
            }
            $CurrentBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild).CurrentBuild
            $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
            $HostName = $computer
            $OSVersion = $CurrentBuild + "." + $UBR

            #$TempTable = New-Object System.Data.DataTable
            #$TempTable.Columns.AddRange(@("ComputerName","Windows Edition","Version","OS Build"))
            #[void]$TempTable.Rows.Add($env:COMPUTERNAME,$ProductName,$Version,$OSVersion)
        
            #Return $TempTable
            $NewLine = "{0}, {1}, {2}" -f $HostName,$CurrentBuild, $UBR
            $NewLine | Add-Content -Path $FilePath\$Outfile
        }

        If ($Computer -eq $env:COMPUTERNAME)
        {
            $Result = Invoke-Command -ScriptBlock $Code
            [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build')
        }
        Else
        {
            Try
            {
                $Result = Invoke-Command -ComputerName $Computer -ScriptBlock $Code -ErrorAction Stop
                [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'OS Build')
            }
            Catch
            {
                $_
            }
        }
        
    }
