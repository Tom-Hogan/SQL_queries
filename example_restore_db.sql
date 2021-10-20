/* ================================================================================================
Purpose:
    Example commands used to restore a database.
 
History:
    2004-01-19  Tom Hogan           Created.
================================================================================================ */

-- ------------------------------------------------------------------------------------------------
-- to set database to single user mode
-- ------------------------------------------------------------------------------------------------
ALTER DATABASE WideWorldImporters
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;
GO


-- ------------------------------------------------------------------------------------------------
-- to restore a backup of one database to another database
-- ------------------------------------------------------------------------------------------------
-- get logical and physical names
RESTORE FILELISTONLY
    FROM DISK = N'X:\Backups\WideWorldImporters.bak';

-- replace logical name (immediately after MOVE) with those listed by first statement
-- replace physical file locations (after the TO on the MOVE lines) with the file 
--    locations and names you are moving to
RESTORE DATABASE WideWorldImporters
    FROM DISK = N'X:\Backups\WideWorldImporters.bak'
    WITH MOVE N'WWI_Primary'
             TO N'D:\SQLData\WideWorldImporters.mdf',
         MOVE N'WWI_Log'
             TO N'L:\SQLLogs\WideWorldImporters_log.ldf',
         REPLACE;


-- ------------------------------------------------------------------------------------------------
-- to restore a database to the same database
-- ------------------------------------------------------------------------------------------------
RESTORE DATABASE WideWorldImporters
    FROM DISK = N'X:\Backups\WideWorldImporters.bak'
    WITH REPLACE;


-- ------------------------------------------------------------------------------------------------
-- to restore a database, then transaction logs
-- ------------------------------------------------------------------------------------------------
RESTORE DATABASE WideWorldImporters
    FROM DISK = N'X:\Backups\WideWorldImporters.bak'
    WITH MOVE N'WideWorldImporters'
             TO N'D:\SQLData\WideWorldImporters.mdf',
         MOVE N'WideWorldImporters_log'
             TO N'L:\SQLLogs\WideWorldImporters_log.ldf',
         REPLACE,
         NORECOVERY;

RESTORE LOG WideWorldImporters
    FROM DISK = 'X:\Backups\WideWorldImporters_tlog_201805010400.trn'
    WITH NORECOVERY;

RESTORE LOG WideWorldImporters
    FROM DISK = 'X:\Backups\WideWorldImporters_tlog_201805010800.trn'
    WITH NORECOVERY;
    /* -- add STOPAT clause to do a point in time recovery
         STOPAT = 'May 1, 2018 6:00:00 AM'; */

RESTORE LOG WideWorldImporters
    WITH RECOVERY;
