function Download-Connector {
    $url = 'https://131.61.226.205/connector/RubrikBackupService.zip'
    $zip_file = 'C:\Users\1086335782.adm\Downloads\RubrikBackupService.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $zip_file)
    Expand-Archive -Path $zip_file -DestinationPath 'C:\Users\1086335782.adm\Downloads\RubrikBackupService'
}