/* ================================================================================================
Purpose:
    Lists SQL Agent jobs.

History:
    2012-08-01  Tom Hogan           Created.
================================================================================================ */
USE msdb;


WITH
cte_job_schedule AS
(
    SELECT  j.job_id,
            CASE
                WHEN s2.enabled = 1
                    THEN 'Yes'
                ELSE 'No'
            END   AS schedule_enabled,
            -- SQL Prompt formatting off
            /* scheduled period */
            CASE
                /* one time */
                WHEN s2.freq_type = 0x1
                    THEN 'Once on ' + convert(varchar(10), cast(cast(s2.active_start_date AS varchar(10)) AS datetime), 102)
                /* daily */
                WHEN s2.freq_type = 0x4
                    THEN 'Daily'
                /* weekly */
                WHEN s2.freq_type = 0x8
                    THEN
                        CASE
                            WHEN s2.freq_recurrence_factor = 1
                                THEN 'Weekly on '
                            ELSE 'Every ' + cast(s2.freq_recurrence_factor AS varchar(5)) + ' weeks on '
                        END
                            + left(     CASE WHEN s2.freq_interval &  1 =  1 THEN 'Sun, ' ELSE '' END 
                                    +   CASE WHEN s2.freq_interval &  2 =  2 THEN 'Mon, ' ELSE '' END 
                                    +   CASE WHEN s2.freq_interval &  4 =  4 THEN 'Tue, ' ELSE '' END
                                    +   CASE WHEN s2.freq_interval &  8 =  8 THEN 'Wed, ' ELSE '' END 
                                    +   CASE WHEN s2.freq_interval & 16 = 16 THEN 'Thu, ' ELSE '' END 
                                    +   CASE WHEN s2.freq_interval & 32 = 32 THEN 'Fri, ' ELSE '' END 
                                    +   CASE WHEN s2.freq_interval & 64 = 64 THEN 'Sat, ' ELSE '' END
                                    , len(      CASE WHEN s2.freq_interval &  1 =  1 THEN 'Sun, ' ELSE '' END
                                            +   CASE WHEN s2.freq_interval &  2 =  2 THEN 'Mon, ' ELSE '' END
                                            +   CASE WHEN s2.freq_interval &  4 =  4 THEN 'Tue, ' ELSE '' END
                                            +   CASE WHEN s2.freq_interval &  8 =  8 THEN 'Wed, ' ELSE '' END
                                            +   CASE WHEN s2.freq_interval & 16 = 16 THEN 'Thu, ' ELSE '' END 
                                            +   CASE WHEN s2.freq_interval & 32 = 32 THEN 'Fri, ' ELSE '' END
                                            +   CASE WHEN s2.freq_interval & 64 = 64 THEN 'Sat, ' ELSE '' END
                                         ) - 1   /* len() ignores trailing spaces */
                                  )
                /* monthly */
                WHEN s2.freq_type = 0x10
                    THEN
                        CASE
                            WHEN s2.freq_recurrence_factor = 1
                                THEN 'Monthly on the '
                            ELSE 'Every ' + cast(s2.freq_recurrence_factor AS varchar(5)) + ' months on the '
                        END 
                            + cast(s2.freq_interval AS varchar(5)) 
                            +   CASE
                                    WHEN s2.freq_interval IN (1, 21, 31)
                                        THEN 'st'
                                    WHEN s2.freq_interval IN (2, 22)
                                        THEN 'nd'
                                    WHEN s2.freq_interval IN (3, 23)
                                        THEN 'rd'
                                    ELSE 'th'
                                END
                /* monthly relative */
                WHEN s2.freq_type = 0x20
                    THEN
                        CASE
                            WHEN s2.freq_recurrence_factor = 1
                                THEN 'Monthly on the '
                            ELSE 'Every ' + cast(s2.freq_recurrence_factor AS varchar(5)) + ' months on the '
                        END
                            +   CASE s2.freq_relative_interval
                                    WHEN 0x01 THEN 'first '
                                    WHEN 0x02 THEN 'second '
                                    WHEN 0x04 THEN 'third '
                                    WHEN 0x08 THEN 'fourth '
                                    WHEN 0x10 THEN 'last '
                                    ELSE ' '
                                END
                            +   CASE s2.freq_interval
                                    WHEN  1 THEN 'Sun'
                                    WHEN  2 THEN 'Mon'
                                    WHEN  3 THEN 'Tue'
                                    WHEN  4 THEN 'Wed'
                                    WHEN  5 THEN 'Thu'
                                    WHEN  6 THEN 'Fri'
                                    WHEN  7 THEN 'Sat'
                                    WHEN  8 THEN 'day'
                                    WHEN  9 THEN 'week day'
                                    WHEN 10 THEN 'weekend day'
                                    ELSE ' '
                                END
                WHEN s2.freq_type = 0x40
                    THEN 'When SQLServerAgent starts'
                WHEN s2.freq_type = 0x80
                    THEN 'When CPUs become idle'
                ELSE ''
            END
                /* plus scheduled time to run */
                +   CASE
                        /* specific times */
                        WHEN s2.freq_subday_type = 0x1
                        OR   s2.freq_type = 0x1
                            THEN ' at '
                                    +   CASE
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 = 0
                                                THEN '12:' + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 < 12
                                                THEN cast(( s2.active_start_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 = 12
                                                THEN cast(( s2.active_start_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                            ELSE cast((( s2.active_start_time % 1000000 ) / 10000 ) - 12 AS varchar(2)) + ':'
                                                    + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                        END
                        /* intervals */
                        WHEN s2.freq_subday_type IN (0x2, 0x4, 0x8)
                            THEN ' every ' + cast(s2.freq_subday_interval AS varchar(5))
                                    +   CASE s2.freq_subday_type
                                            WHEN 0x2 THEN ' second'
                                            WHEN 0x4 THEN ' minute'
                                            WHEN 0x8 THEN ' hour'
                                            ELSE ''
                                        END
                                    +   CASE
                                            WHEN s2.freq_subday_interval > 1
                                                THEN 's'
                                            ELSE ''
                                        END
                        ELSE ''
                    END
                /* plus interval period */
                +   CASE
                        WHEN s2.freq_subday_type IN (0x2, 0x4, 0x8)
                            THEN ' between ' 
                                    +   CASE
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 = 0
                                                THEN '12:' + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 < 12
                                                THEN cast(( s2.active_start_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_start_time % 1000000 ) / 10000 = 12
                                                THEN cast(( s2.active_start_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                            ELSE cast((( s2.active_start_time % 1000000 ) / 10000 ) - 12 AS varchar(2)) + ':'
                                                    + right('00' + cast(( s2.active_start_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                        END
                                    + ' and '
                                    +   CASE
                                            WHEN ( s2.active_end_time % 1000000 ) / 10000 = 0
                                                THEN '12:' + right('00' + cast(( s2.active_end_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_end_time % 1000000 ) / 10000 < 12
                                                THEN cast(( s2.active_end_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_end_time % 10000 ) / 100 AS varchar(2)), 2) + 'am'
                                            WHEN ( s2.active_end_time % 1000000 ) / 10000 = 12
                                                THEN cast(( s2.active_end_time % 1000000 ) / 10000 AS varchar(2)) + ':'
                                                        + right('00' + cast(( s2.active_end_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                            ELSE cast((( s2.active_end_time % 1000000 ) / 10000 ) - 12 AS varchar(2)) + ':'
                                                    + right('00' + cast(( s2.active_end_time % 10000 ) / 100 AS varchar(2)), 2) + 'pm'
                                        END
                          ELSE ''
                    END AS sheduled_run_time
            -- SQL Prompt formatting on
    FROM    dbo.sysjobs         AS j
    JOIN    dbo.sysjobschedules AS js2  ON  js2.job_id = j.job_id
    JOIN    dbo.sysschedules    AS s2   ON  s2.schedule_id = js2.schedule_id
)
SELECT      j.name                                AS job_name,
            CASE
                WHEN j.enabled = 1
                    THEN 'Yes'
                ELSE 'No'
            END                                   AS job_enabled,
            j.description                         AS job_description,
            o.name                                AS job_owner,
            coalesce(sch.sheduled_run_time, '')   AS scheduled_run_time,
            coalesce(sch.schedule_enabled, 'N/A') AS schedule_enabled,
            CASE
                WHEN j.notify_level_email = 0
                    THEN ''
                WHEN j.notify_level_email = 1
                    THEN 'On success'
                WHEN j.notify_level_email = 2
                    THEN 'On failure'
                WHEN j.notify_level_email = 3
                    THEN 'Always'
                ELSE ''
            END                                   AS email_notification,
            isnull(eo.name, '')                   AS email_operator,
            CASE
                WHEN j.notify_level_page = 0
                    THEN ''
                WHEN j.notify_level_page = 1
                    THEN 'On success'
                WHEN j.notify_level_page = 2
                    THEN 'On failure'
                WHEN j.notify_level_page = 3
                    THEN 'Always'
                ELSE ''
            END                                   AS page_notification,
            isnull(po.name, '')                   AS page_operator,
            CASE
                WHEN j.notify_level_eventlog = 0
                    THEN ''
                WHEN j.notify_level_eventlog = 1
                    THEN 'On success'
                WHEN j.notify_level_eventlog = 2
                    THEN 'On failure'
                WHEN j.notify_level_eventlog = 3
                    THEN 'Always'
                ELSE ''
            END                                   AS write_to_event_log,
            c.name                                AS category,
            j.date_created,
            j.date_modified
FROM        dbo.sysjobs             AS j
JOIN        dbo.syscategories       AS c    ON  c.category_id = j.category_id
                                            AND c.name <> 'Report Server'   /* exclude scheduled reports */
LEFT JOIN   sys.database_principals AS o    ON  o.sid = j.owner_sid
LEFT JOIN   cte_job_schedule        AS sch  ON  sch.job_id = j.job_id
LEFT JOIN   dbo.sysoperators        AS eo   ON  eo.id = j.notify_email_operator_id
LEFT JOIN   dbo.sysoperators        AS po   ON  po.id = j.notify_page_operator_id
LEFT JOIN   dbo.sysoperators        AS so   ON  so.id = j.notify_netsend_operator_id
ORDER BY    j.name;
