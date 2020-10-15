###################################################
# Quick script to get a list of MAC addresses     #
# from IP List.                                   #
#                                                 #   
# IP list must be called "computers.txt",         #
# and be put in the same directory as the script. #
#                                                 #
###################################################


$computers = Get-Content .\computers.txt
foreach ($computername in $computers) {
    Get-WmiObject win32_networkadapterconfiguration -computer $computername -Filter "IPEnabled = 'True'" | select DNSHostname, MACAddress, IPAddress
}