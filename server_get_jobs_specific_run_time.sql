/* ================================================================================================
Purpose:
    Lists all jobs that ran between a given time period.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific time period.
 
History:
    2012-08-13  Tom Hogan           Created.
================================================================================================ */
USE msdb;


WITH
cte_details AS
(
    SELECT  DISTINCT
            j.name                                                                                                                                        AS job_name,
            cast(cast(h.run_date AS char(8)) + ' ' + stuff(stuff(right('000000' + cast(h.run_time AS varchar(6)), 6), 3, 0, ':'), 6, 0, ':') AS datetime) AS run_datetime,
            CASE h.run_status
                WHEN 0
                    THEN 'Failed'
                WHEN 1
                    THEN 'Succeeded'
                WHEN 2
                    THEN 'Retry'
                WHEN 3
                    THEN 'Canceled'
                WHEN 4
                    THEN 'In progress'
                ELSE ''
            END                                                                                                                                           AS run_status
    FROM    dbo.sysjobhistory   AS h
    JOIN    dbo.sysjobs         AS j    ON  j.job_id = h.job_id
            /*
            === to get specific time period  ===
             - run time format hhmmss
             - run_date format yyyymmdd
            */
    --WHERE   h.run_time BETWEEN 120000 AND 160000
    --AND     h.run_date = 20171220
)
SELECT      d.job_name,
            d.run_datetime,
            d.run_status
FROM        cte_details AS d
ORDER BY    d.job_name,
            d.run_datetime DESC;
