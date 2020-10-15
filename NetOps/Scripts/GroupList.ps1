$TestFile = "C:\Transfer\Temporary Space"

$GroupList = Get-ADGroup -Filter * -Properties Name, DistinguishedName, `
        GroupCategory, GroupScope, whenCreated, whenChanged, member, memberOf, `
        sIDHistory, SamAccountName, Description |
    Select-Object Name, DistinguishedName, GroupCategory, GroupScope, `
        whenCreated, whenChanged, member, memberOf, SID, SamAccountName, `
        Description, `
        @{name='MemberCount';expression={$._member.count}}, `
        @{name='MemberOfCount';expression={$._memberOf.count}}, `
        @{name='SIDHistory';expression={$._sIDHistory.count}}, `
        @{name='DaysSinceChange';expression=`
            {[math]::Round((New-TimeSpan $._whenChanged).TotalDays,0)}} |
    Sort-Object Name

$GroupList |
    Select-Object Name, SamAccountName, Description, DistinguishedName, `
            GroupCategory, GroupScope, whenCreated, whenChanged, DaysSinceChange, `
            MemberCount, MemberOfCount, SID, SIDHistory |
    Export-Csv $TestFile\GroupList.csv -NoTypeInformation