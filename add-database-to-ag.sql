-- add-database-to-ag.sql
USE master;
GO

CREATE DATABASE MyAGDatabase;
GO
ALTER DATABASE MyAGDatabase SET RECOVERY FULL;
GO

-- A backup is required for seeding to start
BACKUP DATABASE MyAGDatabase TO DISK = '/var/opt/mssql/data/MyAGDatabase.bak';
GO

-- Add the database to the AG. Seeding will happen automatically.
ALTER AVAILABILITY GROUP [MyAG] ADD DATABASE MyAGDatabase;
GO