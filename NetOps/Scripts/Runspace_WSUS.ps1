$fileLocation = "C:\Users\1086335782C\Desktop"  
$fileList = "computers.txt"                         

$Computers = Get-Content "$fileLocation\$fileList"

$runspacepool =[RunSpaceFactory]::CreateRunspacePool(1, 4)
$runspacepool.ApartmentState = "MTA"
$runspacepool.Open()

$codeContainer = {
    Param(
        [string] $ComputerName
    )
    $processes = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        # Create variables
        $args = "/updatecpp /instmssl /instdotnet35 /instpsh /instdotnet4 /instwmf /instmsse /updatetsc /instmsi"
        $WSUSPath = "\\52prpr-fs-003\NCC\Software\WSUS_Offline"

        # Map drive locally
        net use J: "$WSUSPath"
        cd J:\

        # Run updates
        if (Test-Path J:\update.cmd) {
            J:\cmd\DoUpdate.cmd "$args"
        }

        # Clean up. Remove mappings
        cd C:\
        net use J: /delete    
    }

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
    Write-Host "Finished creating runspace for $c. Elapsed time: $elapsed."
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