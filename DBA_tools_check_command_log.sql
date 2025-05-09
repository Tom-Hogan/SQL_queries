/* ================================================================================================
Purpose:
    Gets commands logged from Ola Hallengren's maintenance jobs, sorted by most recent.
 
History:
    2017-08-15  Tom Hogan           Created.
================================================================================================ */
USE DBA_tools;
SET NOCOUNT ON;


SELECT      CommandType,
            Command,
            DatabaseName,
            SchemaName,
            ObjectName,
            IndexName,
            StartTime,
            EndTime,
            cast(datediff(MILLISECOND, StartTime, EndTime) / 1000.00 AS decimal(11, 3)) AS run_time_in_sec,
            ErrorMessage,
            ExtendedInfo
FROM        dbo.CommandLog
--WHERE       CommandType = 'ALTER_INDEX' /* DBCC_CHECKDB, UPDATE_STATISTICS, ALTER_INDEX */
ORDER BY    StartTime DESC;
