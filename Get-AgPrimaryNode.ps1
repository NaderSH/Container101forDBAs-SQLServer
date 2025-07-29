function Get-AgPrimaryNode {
    param (
        [string[]]$AgNodes,
        [string]$User,
        [string]$Password,
        [int]$QueryTimeout = 30
    )
    $query = 'SELECT @@SERVERNAME as PrimaryNode
            FROM sys.dm_hadr_availability_replica_states
            WHERE role = 1;'
    foreach ($node in $AgNodes) {
        $primaryNode = (Invoke-Sqlcmd -Query $query -ServerInstance $node -Database 'master' -Username $User -Password $Password -TrustServerCertificate -QueryTimeout $QueryTimeout).PrimaryNode
        if ($primaryNode -ne $null){
            Write-Output($primaryNode)
            break
        }
    }
}
