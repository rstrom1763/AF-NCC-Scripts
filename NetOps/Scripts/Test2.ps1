Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Form = New-Object System.Windows.Forms.Form

$script:Label = New-Object System.Windows.Forms.Label
$script:Label.AutoSize = $true
$script:Form.Controls.Add($Label)
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000
$script:CountDown = 60
$Timer.add_Tick( 
    {
    $script:Label.Text = "Your system will reboot in $CountDown seconds."
    $script:CountDown--
    }
)
$script:Timer.Start()
$script:Form.ShowDialog()
