$InFile = "RemoveProfiles.txt"
$FilePath = "C:\Transfer\PSScripts"

$computers = Get-Content "$FilePath\$InFile"


ForEach ($computer in $computers) {
    Invoke-Command -Computername $computer -AsJob -ScriptBlock {
        Get-WMIObject -class Win32_UserProfile | Where {(!$_.Special) -and ($_.ConvertToDateTime($_.LastUseTime) -lt (Get-Date).AddDays(-1))} | Remove-WmiObject
    }
}
