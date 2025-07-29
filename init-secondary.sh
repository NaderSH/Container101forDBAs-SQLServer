#!/bin/bash
# init-secondary.sh

SA_PASSWORD='YourStrong!Password' # !!! CHANGE THIS !!!
SQLCMD="/opt/mssql-tools/bin/sqlcmd"
SQLCMD_ARGS="-S localhost -U sa -P $SA_PASSWORD"

echo "Waiting for SQL Server on sqlnode2 to be ready..."
until $SQLCMD $SQLCMD_ARGS -Q "SELECT 1;" &>/dev/null; do
    echo -n .
    sleep 2
done
echo "SQL Server on sqlnode2 is ready!"

echo "Waiting for primary replica (sqlnode1) to be configured..."
while [ ! -f /certs/primary_ready.flag ]; do
    echo -n .
    sleep 5
done

echo "Primary is ready! Configuring secondary replica..."

# Create the master key
$SQLCMD $SQLCMD_ARGS -Q "CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$SA_PASSWORD';"

# Create the certificate from the backup on the shared volume
$SQLCMD $SQLCMD_ARGS -Q "CREATE CERTIFICATE ag_certificate FROM FILE = '/certs/ag_certificate.cer' WITH PRIVATE KEY (FILE = '/certs/ag_certificate.key', DECRYPTION BY PASSWORD = '$SA_PASSWORD');"

# Create the HADR endpoint
$SQLCMD $SQLCMD_ARGS -Q "CREATE ENDPOINT [Hadr_endpoint] STATE=STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL) FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE ag_certificate, ENCRYPTION = REQUIRED ALGORITHM AES);"

# Join the Availability Group
$SQLCMD $SQLCMD_ARGS -Q "ALTER AVAILABILITY GROUP [MyAG] JOIN WITH (CLUSTER_TYPE = NONE);"
$SQLCMD $SQLCMD_ARGS -Q "ALTER AVAILABILITY GROUP [MyAG] GRANT CREATE ANY DATABASE;"

echo "Secondary setup complete."

# Keep the container running
tail -f /dev/null