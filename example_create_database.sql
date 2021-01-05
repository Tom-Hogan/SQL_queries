/* ================================================================================================
Purpose:
    Example commands to create a database.
 
History:
    2004-12-16  Tom Hogan           Created.
================================================================================================ */

-- create database syntax
CREATE DATABASE DBA_Tools
    ON  (
        NAME = DBA_Tools,
        FILENAME = 'E:\SQLData\DBA_Tools.mdf',
        SIZE = 64MB,
        FILEGROWTH = 64MB   --, MAXSIZE = 475000MB
        )
    LOG ON  (
            NAME = DBA_Tools_log,
            FILENAME = 'F:\SQLLogs\DBA_Tools_log.ldf',
            SIZE = 64MB,
            FILEGROWTH = 64MB    --, MAXSIZE = 95000MB
            );


-- set recovery format
ALTER DATABASE DBA_Tools
    SET RECOVERY SIMPLE;    -- FULL | BULK_LOGGED | SIMPLE


-- change DB owner to SA
ALTER AUTHORIZATION
    ON DATABASE::DBA_Tools
    TO sa;