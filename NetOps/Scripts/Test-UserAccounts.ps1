function Get-LocalUser ($ComputerName = $env:COMPUTERNAME) {
    Get-WmiObject -Query "Select * from Win32_UserAccount Where LocalAccount = 'False'" -ComputerName $ComputerName |
    Select-Object -ExpandProperty Name
}
