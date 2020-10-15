$fileLocation = "C:\Users\1086335782C\Desktop"  
$fileList = "PFX-20180925.txt"                         

$Computers = Get-Content "$fileLocation\$fileList"

$runspacepool =[RunSpaceFactory]::CreateRunspacePool(1, 4)
$runspacepool.ApartmentState = "MTA"
$runspacepool.Open()

$codeContainer = {
    Param(
        [string] $ComputerName
    )
    $processes = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-ChildItem C:\ -Include ("*.p12", "*.pfx") -Exclude ("preflight.p12", "gazette.pfx", "trustedps.pfx", "AFAS1.af.mil.pfx", "mrs_hv.pfx") -Recurse | foreach ($_) {
            Write-Host $env:ComputerName + $_.FullName
            Remove-Item $_.fullname -Force
        }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        (New-Object -ComObject Shell.Application).NameSpace(0x0a).Items() | Select-Object Name.Size.Path
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