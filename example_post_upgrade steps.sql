/* ================================================================================================
Purpose:
    Steps to be run against an upgraded database (i.e. from v2012 to v2016).
        1. Take backups
        2. Page count checks
        3. Integrity checks
        4. Update statistics
        5. Refresh view definitions
        6. Check compatibility levels
        7. Verify counts of objects
        8. Check configurations

    *** Run one section at a time.

History:
    2016-12-19  Tom Hogan           Created, based on article by Thomas LaRock.
================================================================================================ */
RAISERROR(N'You want to run these statements one at a time.', 20, 1) WITH LOG;
GO

-- 1. Take backups
--  See script (example_database_backup.sql).

-- 2. Page count checks
--  Checks and fixes any page count inaccuracies.
DBCC UPDATEUSAGE(0);

-- 3. Integrity checks
DBCC CHECKDB WITH NO_INFOMSGS, DATA_PURITY;

-- 4. Update statistics
EXEC sys.sp_MSforeachtable @command1 = 'UPDATE STATISTICS ? WITH FULLSCAN';
-- OR
-- EXEC sp_updatestats;

-- 5. Refresh view definitions
--  See script (db_refresh_all_views.sql).

-- 6. Check compatibility levels
--  Can check this value by either looking at database's proprties or running this query:
/*
SELECT      name,
            compatibility_level
FROM        sys.databases
WHERE       database_id > 4
ORDER BY    name;
-- */

-- 7. Verify counts of objects

-- 8. Check configurations
