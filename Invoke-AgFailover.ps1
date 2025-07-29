function Invoke-AgFailover {
    param (
        [string[]]$AgNodes,
        [string]$NewPrimary,
        [string]$User,
        [string]$Password,
        [int]$QueryTimeout = 30
    )
    $primaryIdentifierQuery = 'SELECT @@SERVERNAME as PrimaryNode
            FROM sys.dm_hadr_availability_replica_states
            WHERE role = 1;'
    $agNameQuery = 'SELECT name FROM sys.availability_groups;'  
    # capture the current primary node     
    foreach ($node in $AgNodes) {
        $currentPrimary = (Invoke-Sqlcmd -Query $primaryIdentifierQuery -ServerInstance $node -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout).PrimaryNode
        if ($currentPrimary -ne $null){
            Write-Host "[$currentPrimary] is the current primary!!"
            break
        }
    }
    if($currentPrimary -eq $NewPrimary){
        Write-Host "The current primary is your target primary, no need to failover!!"
        return
    }
    Write-Host "Moving AG to node [$NewPrimary] ..."
    # capture AG name
    $agName = (Invoke-Sqlcmd -Query $agNameQuery -ServerInstance $currentPrimary -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout).name
    # prepare the secondary for manual failover
    $secondaryFailoverPrepQuery = "ALTER AVAILABILITY GROUP [$agName] SET (ROLE = SECONDARY);"
    Invoke-Sqlcmd -Query $secondaryFailoverPrepQuery -ServerInstance $NewPrimary -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout
    # move AG to the new primary
    $agFailoverQuery = "ALTER AVAILABILITY GROUP [$agName] FAILOVER;"
    Invoke-Sqlcmd -Query $agFailoverQuery -ServerInstance $currentPrimary -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout
    # check the current primary after failover
    foreach ($node in $AgNodes) {
    $currentPrimary = (Invoke-Sqlcmd -Query $primaryIdentifierQuery -ServerInstance $node -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout).PrimaryNode
        if ($currentPrimary -ne $null){
            Write-Host "[$currentPrimary] is the current primary!!"
            break
        }
    }
}