/* ================================================================================================
Purpose:
    Lists a series of top 10 counts of reports for a given time period that were run against the
    current reporting instance.
     - most executed
     - longest running
     - largest (most rows)
     - users (called by most users)

Notes:
    Uses custom view (custom_execution_log) to get data about report runs.

History:
    Unknown     Tom Hogan       Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


DECLARE @start_date datetime,
        @end_date   datetime;

SET @start_date = '20150301'; /* format yyyymmdd */
SET @end_date   = '20150331'; /* format yyyymmdd */


/* most executed */
SELECT      TOP ( 10 )
            report_name,
            count(report_name)         AS executions,
            avg(time_to_retrieve_data) AS average_time_to_retrieve_data,
            avg(time_to_process)       AS average_time_to_process,
            avg(time_to_render)        AS average_time_to_render,
            avg(row_count)             AS average_row_count
FROM        dbo.custom_execution_log
WHERE       time_start >= @start_date
AND         time_start <= @end_date
GROUP BY    report_name
ORDER BY    count(report_name) DESC,
            report_name;


/* longest running */
SELECT      TOP ( 10 )
            report_name,
            count(report_name)                          AS executions,
            avg(datediff(SECOND, time_start, time_end)) AS average_time_in_sec
FROM        dbo.custom_execution_log
WHERE       time_start >= @start_date
AND         time_start <= @end_date
GROUP BY    report_name
ORDER BY    average_time DESC,
            report_name;


/* largest */
SELECT      TOP ( 10 )
            report_name,
            count(report_name) AS executions,
            avg(row_count)     AS average_rows
FROM        dbo.custom_execution_log
WHERE       time_start >= @start_date
AND         time_start <= @end_date
GROUP BY    report_name
ORDER BY    average_rows DESC;


/* users */
SELECT      TOP ( 10 )
            run_by,
            count(report_name) AS executions
FROM        dbo.custom_execution_log
WHERE       time_start >= @start_date
AND         time_start <= @end_date
AND         run_by NOT IN ('Domain\user')
GROUP BY    run_by
ORDER BY    executions DESC;
