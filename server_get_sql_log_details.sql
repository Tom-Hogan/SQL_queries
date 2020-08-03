/* ================================================================================================
Purpose:
    Lists the contents of the SQL Server logs or SQL Agent logs.

History:
    2017-09-20  Tom Hogan
                - Created.  Baaed on this article:
                  https://www.sqlmatters.com/Articles/Searching-ALL-SQL-Server-Logs-using-TSQL.aspx
================================================================================================ */
USE master;


DECLARE @search_string_1 nvarchar(4000),
        @search_string_2 nvarchar(4000),
        @log_type        int,
        @log_count       int = 0;

SET @search_string_1 = N'';     -- update with string you want to search for
SET @search_string_2 = N'';     -- update with an additional string to search for to further refine the results
SET @log_type = 1;              -- 1 = SQL Server log, 2 = SQL Agent log


-- ------------------------------------------------------------------------------------------------
-- create temp tables to hold results
-- ------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS #LogList;
DROP TABLE IF EXISTS #LogInfo;

CREATE TABLE #LogInfo (
    LogDate     datetime       NOT NULL,
    ProcessInfo nvarchar(4000) NULL,
    ErrorText   nvarchar(4000) NULL
);


-- ------------------------------------------------------------------------------------------------
-- load list of all logs to temp table
-- ------------------------------------------------------------------------------------------------
INSERT INTO #LogList
EXEC sys.xp_enumerrorlogs
    @log_type;


-- ------------------------------------------------------------------------------------------------
-- loop through the logs and load results to temp table
-- ------------------------------------------------------------------------------------------------
WHILE @log_count <= ( SELECT max(LogNumber) FROM #LogList )
BEGIN
    BEGIN TRY
        INSERT INTO #LogInfo
        EXEC sys.xp_readerrorlog 
            @log_count,
            @log_type,
            @search_string_1,
            @search_string_2;

    END TRY
    BEGIN CATCH
        PRINT 'Error occurred processing file ' + cast(@log_count AS varchar(10));
    END CATCH;

    SET @log_count = @log_count + 1;
END;


-- ------------------------------------------------------------------------------------------------
-- return the results
-- ------------------------------------------------------------------------------------------------
SELECT      LogDate,
            ProcessInfo,
            ErrorText
FROM        #LogInfo
WHERE       ProcessInfo NOT IN ('Backup', 'Logon')
AND         ErrorText NOT LIKE 'DBCC%'
ORDER BY    LogDate DESC
;
