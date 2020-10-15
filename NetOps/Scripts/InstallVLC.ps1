$fileLocation = "C:\Users\1086335782C\Desktop"  # Location of computer list
$fileList = "VLC.txt" # Name of file list. Should be compuer names (not FQDN)
$fileEXEC = "C:\installfiles\Deploy\vlc-3.0.3-win64.exe"
$Params = "/L=1033 /S"

$computers = "$fileLocation\$fileList"

$runspacepool =[RunSpaceFactory]::CreateRunspacePool(1, 4)
$runspacepool.ApartmentState = "MTA"
$runspacepool.Open()

$codeContainer = {
    Param(
        [string] $ComputerName
    )
    <#############################################################################################
      Everything between the {} after -ScriptBlock will run on the remote system.
      Make sure whatever script you run here does not cause the remote system to wait for input.
      Otherwise, your script will never finish. 
    #############################################################################################>
    $processes = Invoke-Command -ComputerName $ComputerName -ScriptBlock {

    # BEGIN SCRIPT
    psexec -s -d powershell.exe Enable-PSRemoting -force
    cd C:\installfiles\Deploy
    Start-Sleep -Seconds 5
    & "$fileEXEC" $Params
    } # END SCRIPT

    return $processes
}

$threads = @()

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($c in $computers) {
    $runspaceObject = [PSCustomObject] @{
        Runspace = [PowerShell]::Create()
        Invoker = $null
    }
    $runspaceObject.Runspace.RunSpacePool = $runspacePool
    $runspaceObject.Runspace.AddScript($codeContainer) | Out-Null
    $runspaceObject.Runspace.AddArgument($c) | Out-Null
    $runspaceObject.Invoker = $runspaceObject.Runspace.BeginInvoke()
    $threads += $runspaceObject
    $elapsed = $stopwatch.Elapsed
    Write-Host "Finished creating runspace for $c. Elapsed time: $elapsed"
}
$elapsed = $stopwatch.Elapsed
Write-Host "All remote commands completed. Elapsed time: $elapsed"

while ($threads.Invoker.IsCompleted -contains $false) {}
$elapsed = $stopwatch.Elapsed
Write-Host "All runspaces completed. Elapsed time: $elapsed"

$threadResults = @()
foreach ($t in $threads) {
    $threadResults += $t.Runspace.EndInvoke($t.Invoker)
    $t.Runspace.Dispose()
}

$runspacepool.Close()
$runspacepool.Dispose()