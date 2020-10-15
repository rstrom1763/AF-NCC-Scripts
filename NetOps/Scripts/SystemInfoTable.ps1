# Remote System Information
# Shows hardware and OS details from a list of PCs
# Craig Courtney 03022016

# Get list of computers from file
$ComputerList = Get-Content C:\Transfer\PSScripts\good.txt

Clear-Host
# Write-Host "-------------------------------------------------------"

$ComputerTable = "Computer Listing"

# Function to get IP address from computer name
function Get-HostToIP($hostname) {
    $result = [system.net.dns]::GetHostByName($hostname)
    $result.AddressList | ForEach-Object {$_.IPAddressToString}
}

# Create table object
$table = New-Object System.Data.DataTable "$ComputerTable"

# Define columns
$col1 = New-Object System.Data.DataColumn ColumnName1,([string])
$col2 = New-Object System.Data.DataColumn ColumnName2,([string])
$col3 = New-Object System.Data.DataColumn ColumnName3,([string])
$col4 = New-Object System.Data.DataColumn ColumnName4,([string])
$col5 = New-Object System.Data.DataColumn ColumnName5,([string])
$col6 = New-Object System.Data.DataColumn ColumnName6,([string])
$col7 = New-Object System.Data.DataColumn ColumnName7,([string])
$col8 = New-Object System.Data.DataColumn ColumnName8,([string])
$col9 = New-Object System.Data.DataColumn ColumnName9,([string])
$col10 = New-Object System.Data.DataColumn ColumnName10,([string])
$col11 = New-Object System.Data.DataColumn ColumnName11,([string])

# Add the columns
$table.columns.Add($col1)
$table.columns.Add($col2)
$table.columns.Add($col3)
$table.columns.Add($col4)
$table.columns.Add($col5)
$table.columns.Add($col6)
$table.columns.Add($col7)
$table.columns.Add($col8)
$table.columns.Add($col9)
$table.columns.Add($col10)
$table.columns.Add($col11)

# Create a row
$row = $table.NewRow()

# Enter data in the row
$row.ColumnName1 =  "Computer Name"
$row.ColumnName2 =  "IP Address"
$row.ColumnName3 =  "Manufacturer"
$row.ColumnName4 =  "Model"
$row.ColumnName5 =  "Serial Number"
$row.ColumnName6 =  "CPU"
$row.ColumnName7 =  "RAM"
$row.ColumnName8 =  "Operating System"
$row.ColumnName9 =  "Version"
$row.ColumnName10 =  "Last Boot"
$row.ColumnName11 = "User"

# Add the row to the table
$table.Rows.Add($row)

# Add the rest of the rows
foreach ($Computer in $ComputerList) {

    # Test connection
    if (Test-Connection $Computer -Count 1 -ErrorAction 0 -Quiet) {
        $computerSystem = get-wmiobject Win32_ComputerSystem -Computer $Computer -ErrorAction SilentlyContinue
        $computerBIOS =   get-wmiobject Win32_BIOS -Computer $Computer -ErrorAction SilentlyContinue
        $computerOS =     Get-CimInstance CIM_OperatingSystem
        $computerCPU =    get-wmiobject Win32_Processor -Computer $Computer -ErrorAction SilentlyContinue
        $netadapter =     Get-WmiObject win32_networkadapterconfiguration -Filter IPEnabled=TRUE -ComputerName $Computer -ErrorAction SilentlyContinue

        # Create next row
        $row = $table.NewRow()

        $row.ColumnName1 =  $computerSystem.Name
        $row.ColumnName2 =  (Get-HostToIP($Computer))
        $row.ColumnName3 =  $computerSystem.Manufacturer
        $row.ColumnName4 =  $computerSystem.Model
        $row.ColumnName5 =  $computerBIOS.SerialNumber
        $row.ColumnName6 =  $computerCPU.Name
        $row.ColumnName7 =  "{0:N2}" -f ($computerSystem.TotalPhysicalMemory / 1GB) + "GB"
        $row.ColumnName8 =  $computerOS.caption
        $row.ColumnName9 =  $computerOS.version
        $row.ColumnName10 =  (Get-CimInstance Win32_operatingsystem -ComputerName $computer).lastbootuptime
        $row.ColumnName11 = $computerSystem.UserName

        #Add the row to the table
        $table.Rows.Add($row)
    }
}

# Display the table
$table | Format-Table -AutoSize
$tabCSV = $table | Export-Csv C:\Transfer\PSScripts\ComputerList.csv -NoTypeInformation