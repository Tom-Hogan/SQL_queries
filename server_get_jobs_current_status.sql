/* ================================================================================================
Purpose:
    Lists the most recent outcome for SQL Agent jobs.

History:
    2008-02-13  Tom Hogan
                - Created.
================================================================================================ */
USE msdb;


DECLARE @job_name nvarchar(128);

SET @job_name = N'All';     -- update with job name or leave as 'All' to get all jobs


-- return results
SELECT      j.name                                                                                      AS job_name,
            CASE
                WHEN h.run_date IS NULL
                OR   h.run_time IS NULL
                    THEN NULL
                ELSE cast(cast(h.run_date AS char(8)) + ' ' + stuff(stuff(right('000000' + cast(h.run_time AS varchar(6)), 6), 3, 0, ':'), 6, 0, ':') AS datetime)
            END                                                                                         AS last_run_datetime,
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
            END                                                                                         AS last_run_status,
            stuff(stuff(right('000000' + cast(h.run_duration AS varchar(6)), 6), 3, 0, ':'), 6, 0, ':') AS [last_run_duration (HH:MM:SS)],
            h.message                                                                                   AS last_run_status_message,
            CASE s.next_run_date
                WHEN 0
                    THEN NULL
                ELSE
                    cast(cast(s.next_run_date AS char(8)) + ' ' + stuff(stuff(right('000000' + cast(s.next_run_time AS varchar(6)), 6), 3, 0, ':'), 6, 0, ':') AS datetime)
            END                                                                                         AS next_run_datetime
FROM        dbo.sysjobs         AS j
JOIN        dbo.syscategories   AS c    ON  c.category_id = j.category_id
                                            -- filter out scheduled reports
                                        AND c.name <> 'Report Server'
LEFT JOIN   (
            SELECT      job_id,
                        min(next_run_date)  AS next_run_date,
                        min(next_run_time)  AS next_run_time
            FROM        dbo.sysjobschedules
            GROUP BY    job_id
            )                   AS s    ON  s.job_id = j.job_id
LEFT JOIN   (
            SELECT  job_id,
                    run_date,
                    run_time,
                    run_status,
                    run_duration,
                    message,
                    row_number() OVER ( PARTITION BY job_id
                                        ORDER BY run_date DESC,
                                                 run_time DESC
                                      ) AS history_order
            FROM    dbo.sysjobhistory
            WHERE   step_id = 0
            )                   AS h    ON  h.job_id = j.job_id
                                        AND h.history_order = 1
WHERE       j.enabled = 1
AND         j.name =    (
                        CASE
                            WHEN @job_name = 'All'
                                THEN j.name
                            ELSE @job_name
                        END
                        )
ORDER BY    j.name
;
