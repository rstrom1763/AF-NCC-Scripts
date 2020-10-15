$MSI0 = "{716E0306-8318-4364-8B8F-0CC4E9376BAC}"
$MSI1 = "{A9CF9052-F4A0-475D-A00F-A8388C62DD63}"
$MSI2 = "{37477865-A3F1-4772-AD43-AAFC6BCFF99F}"
$MSI3 = "{C04E32E0-0416-434D-AFB9-6969D703A9EF}"
$MSI4 = "{86493ADD-824D-4B8E-BD72-8C5DCDC52A71}"
$MSI5 = "{F662A8E6-F4DC-41A2-901E-8C11F044BDEC}"
$MSI6 = "{196467F1-C11F-4F76-858B-5812ADC83B94}"
$MSI7 = "{859DFA95-E4A6-48CD-B88E-A3E483E89B44}"
$MSI8 = "{355B5AC0-CEEE-42C5-AD4D-7F3CFD806C36}"
$MSI9 = "{1D95BA90-F4F8-47EC-A882-441C99D30C1E}"


$FilePath0 = "C:\Windows\System32"
$FilePath1 = "C:\Windows\sysWOW64"

$arg0 = "/x"
$arg1 = "/qb-"
$arg2 = "/q"
$arg3 = "msxml4*.dll"

#workflow test {
    #parallel {
        if (Test-Path "$FilePath0\msxml4*.*") {
            # Removing MSXML 4.0 SP2.....
            msiexec.exe $arg0 "$MSI0" $arg1
            msiexec.exe $arg0 "$MSI1" $arg1
            msiexec.exe $arg0 "$MSI2" $arg1
            msiexec.exe $arg0 "$MSI3" $arg1
            msiexec.exe $arg0 "$MSI4" $arg1
            msiexec.exe $arg0 "$MSI5" $arg1

            # Removing MSXML 4.0 SP3 ....
            msiexec.exe $arg0 "$MSI6" $arg1
            msiexec.exe $arg0 "$MSI7" $arg1
            msiexec.exe $arg0 "$MSI8" $arg1
            msiexec.exe $arg0 "$MSI9" $arg1

            if (Test-Path "$FilePath0\msxml4*.*") {
                Remove-Item "$FilePath0\msxml4*.*" -Force
            }

            if (Test-Path "$FilePath1\msxml4*.*") {
                Remove-Item "$FilePath1\msxml4*.*" -Force
            }
        }
    #}
#}

test