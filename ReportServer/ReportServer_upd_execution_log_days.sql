/* ================================================================================================
Purpose:
    Updates the number of days report execution data is retained.

History:
    2013-10-11  Tom Hogan           Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


UPDATE  dbo.ConfigurationInfo
SET     value = '90'
WHERE   name = 'ExecutionLogDaysKept';
