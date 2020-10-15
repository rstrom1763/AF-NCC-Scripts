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