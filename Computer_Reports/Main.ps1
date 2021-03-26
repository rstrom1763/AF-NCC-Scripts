#Send-Job -computers "C:\Strom\computers.txt" -outputURI "http://prprl-05teb9:8081/write"

Get-Report -jsonDir "C:/users/ryan/documents/github/Personal-projects/work_node/data" -exportCSV C:/strom/report.csv -adCacheFile D:/adcache.csv -base "McConnell AFB"