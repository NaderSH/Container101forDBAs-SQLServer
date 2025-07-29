#!/bin/bash
# init-primary.sh

SA_PASSWORD='YourStrong!Password' # !!! CHANGE THIS !!!
SQLCMD="/opt/mssql-tools/bin/sqlcmd"
SQLCMD_ARGS="-S localhost -U sa -P $SA_PASSWORD"

echo "Waiting for SQL Server on sqlnode1 to be ready..."
until $SQLCMD $SQLCMD_ARGS -Q "SELECT 1;" &>/dev/null; do
    echo -n .
    sleep 2
done

echo "SQL Server on sqlnode1 is ready!"
echo "Configuring Primary Replica and AG!"

# Run the consolidated setup script
$SQLCMD $SQLCMD_ARGS -i /usr/src/app/create-ag-and-login.sql

# Create a flag file to signal that the primary is configured and cert is ready
touch /certs/primary_ready.flag
echo "Primary setup complete. Flag file created."

# Keep the container running
tail -f /dev/null