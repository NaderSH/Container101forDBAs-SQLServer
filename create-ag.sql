-- create-ag.sql
USE [master];
GO

-- 1. Create and backup the certificate for endpoint authentication
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrong!Password';
GO
CREATE CERTIFICATE ag_certificate WITH SUBJECT = 'AG Certificate for Demo';
GO
BACKUP CERTIFICATE ag_certificate
TO FILE = '/certs/ag_certificate.cer'
WITH PRIVATE KEY (
    FILE = '/certs/ag_certificate.key',
    ENCRYPTION BY PASSWORD = 'YourStrong!Password'
);
GO

-- 2. Create the HADR endpoint
CREATE ENDPOINT [Hadr_endpoint]
    STATE=STARTED
    AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATA_MIRRORING (
        ROLE = ALL,
        AUTHENTICATION = CERTIFICATE ag_certificate,
        ENCRYPTION = REQUIRED ALGORITHM AES
    );
GO

-- 3. Create the Availability Group
CREATE AVAILABILITY GROUP [MyAG]
WITH (
    CLUSTER_TYPE = NONE
)
FOR REPLICA ON
    N'sqlnode1' WITH (
        ENDPOINT_URL = N'tcp://sqlnode1:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL, -- MANUAL is appropriate for traditional cluster-less AGs
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
    ),
    N'sqlnode2' WITH (
        ENDPOINT_URL = N'tcp://sqlnode2:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL,
        SEEDING_MODE = AUTOMATIC,
        SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
    );
GO

-- 4. Create the Listener
ALTER AVAILABILITY GROUP [MyAG]
ADD LISTENER N'MyAGListener' (PORT = 1433);
GO

PRINT 'AG and Listener created successfully.';