Param($computername)

Function Choose-Result{
    param(
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        $Results)

if ($results.name.count -gt 1){
            #Prepare for the loop.
            $nCount = 0
            Write-Host "`r`n"
            #Write out all of the results, including an escape number at the end.
            $Results.name | % {Write-Host "$(($nCount + 1).ToString()): $($_)"; $nCount++}
            Write-Host ("`r`n$(($nCount + 1).ToString()): None of these.")
            #Prompt the user to make a selection.
            [int]$nSelect = Read-Host "Which SCCM Packge would you like to invoke on $computername"
            #Cancel the statement if they used any number outside of the allowed range.
            if (($nSelect -gt $Results.count) -or ($nSelect -le 0)){
                Write-Host "Lookup has been cancelled by user.`r`n"
                return $Null
            }
            #Return their selection.
            else{
                return $Results[$nSelect-1]
            }
        }
        else{
            return $objResults.value
        }
    }

Function Trigger-AppInstallation
{
Param
(
[String][Parameter(Mandatory=$True, Position=1)] $Computername,
[String][Parameter(Mandatory=$True, Position=2)] $AppName,
[ValidateSet("Install","Uninstall")]
[String][Parameter(Mandatory=$True, Position=3)] $Method
)
Begin {
$Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
$Args = @{EnforcePreference = [UINT32] 0
Id = "$($Application.id)"
IsMachineTarget = $Application.IsMachineTarget
IsRebootIfNeeded = $False
Priority = 'High'
Revision = "$($Application.Revision)" }
}
Process
{
Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Args
}
End {}
}

$appname = (choose-result (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername)).name
Trigger-AppInstallation -Computername $computername -AppName $appname -Method Install


