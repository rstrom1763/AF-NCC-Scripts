# Remote System Information
# Shows hardware and OS details from a list of PCs
# Craig Courtney 03022016

# Get list of computers from file
$ComputerList = Get-Content C:\Users\1086335782C\Desktop\list.txt

Clear-Host
Write-Host "-------------------------------------------------------"



foreach ($Computer in $ComputerList) {

    # Test connection
    if (Test-Connection $Computer -Count 1 -ErrorAction 0 -Quiet) {
        $computerSystem = get-wmiobject Win32_ComputerSystem -Computer $Computer -ErrorAction SilentlyContinue
#        $computerBIOS = get-wmiobject Win32_BIOS -Computer $Computer -ErrorAction SilentlyContinue
        $computerOS = get-wmiobject Win32_OperatingSystem -Computer $Computer -ErrorAction SilentlyContinue
#        $computerCPU = get-wmiobject Win32_Processor -Computer $Computer -ErrorAction SilentlyContinue
        # $computerHDD = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter drivetype=3

        Write-Host "System Name: " $computerSystem.Name
        Write-Host "IP Address: " $Computer
        
 <#       
        Write-host "Manufacturer: " $computerSystem.Manufacturer
        Write-host "Model: " $computerSystem.Model
        Write-host "Serial Number: " $computerBIOS.SerialNumber
        Write-host "CPU: " $computerCPU.Name
        Write-Host "RAM: " (($computerSystem.TotalPhysicalMemory) / 1000000000) "GB"
#>        
        
        Write-host "Operating System: " $computerOS.caption ", Service Pack: " $computerOS.ServicePackMajorVersion
        Write-host "User logged In: " $computerSystem.UserName
        Write-host "Last Reboot: " $computerOS.ConvertToDateTime($computerOS.LastBootUpTime)
        Write-Host ""
        Write-Host "-------------------------------------------------------"

    }
}