$computers = Get-Content "C:\Transfer\PSScripts\RequiresPush.txt"


ForEach ($computer in $computers) {
    Invoke-Command -Computername $computer -AsJob -ScriptBlock {

        # Stop scheduled task
        Unregister-ScheduledTask "Cyber Awareness Popup" -Confirm:$false
        # Remove Popup folder
        Remove-Item -Path C:\installfiles\Popup -Force -Recurse -ErrorAction SilentlyContinue
    }
}
