# For the line below, replace the location in the quotes with a csv of computers, preferrably by IP

$computers = Get-Content "C:\Users\1086335782C\Desktop\Certs.txt"
$Patch64 = "windows10.0-kb4487021-x64_23bb68e07454a4c676baab77838f742de22e117b.msu"

ForEach ($computer in $computers) {
    Invoke-Command -Computername $computer -AsJob -ScriptBlock {
        Copy-Item \\52prpr-fs-001\Patching\Plugins\KB4487021\Deploy\windows10.0-kb4487021-x64_23bb68e07454a4c676baab77838f742de22e117b.msu C:\installfiles\Deploy -Force
        wusa.exe /install "C:\installfiles\Deploy\windows10.0-kb4487021-x64_23bb68e07454a4c676baab77838f742de22e117b.msu" /quiet /norestart
    }
}