function Compare-Lists {
    
    Param([Parameter(Mandatory=$True)][String]$list1,[String]$list2)

    $worklist1 = Get-Content $list1 | Sort-Object | Get-Unique
    $worklist2 = Get-Content $list2 | Sort-Object | Get-Unique

    foreach ($computer in $worklist1){
    
        foreach($i in $worklist2){

            if ( $i -eq $computer){

                Write-Host $computer

               }

        }

    }

}
