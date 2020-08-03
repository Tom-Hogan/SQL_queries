/* ================================================================================================
Purpose:
    Lists SQL Agent jobs and their associated steps.

History:
    2008-02-13  Tom Hogan           Created.
    2011-05-16  Tom Hogan           Added job schedules based on work done by "Cowboy DBA" and John Arnott.
================================================================================================ */
USE msdb;


-- get job schedules
SELECT      l.name            AS job_owner,
            c.name            AS job_category,
            j.name            AS job_name,
            CASE
                WHEN j.enabled = 1
                    THEN 'Yes'
                ELSE 'No'
            END               AS job_enabled,
            js.step_id        AS job_step,
            js.step_name      AS step_name,
            js.subsystem      AS step_type,
            js.command        AS step_command,
            CASE js.on_success_action
                WHEN 1
                    THEN 'Quit the job reporting sucess'
                WHEN 2
                    THEN 'Quit the job reporting failure'
                WHEN 3
                    THEN 'Go to the next step'
                WHEN 4
                    THEN 'Go to step ' + cast(js.on_success_step_id AS varchar(2))
                ELSE ''
            END               AS on_step_success,
            js.retry_attempts,
            js.retry_interval AS retry_interval_in_minutes,
            CASE js.on_fail_action
                WHEN 1
                    THEN 'Quit the job reporting sucess'
                WHEN 2
                    THEN 'Quit the job reporting failure'
                WHEN 3
                    THEN 'Go to the next step'
                WHEN 4
                    THEN 'Go to step ' + cast(js.on_fail_step_id AS varchar(2))
                ELSE ''
            END               AS on_step_failure
FROM        dbo.sysjobs                     AS j
JOIN        dbo.syscategories               AS c    ON  c.category_id = j.category_id
                                                        -- filter out scheduled reports
                                                    AND c.name <> 'Report Server'
                                                        -- filter out replication
                                                    AND c.name NOT LIKE 'repl%'
JOIN        dbo.sysjobsteps                 AS js   ON  js.job_id = j.job_id
LEFT JOIN   master.sys.server_principals    AS l    ON  l.principal_id = j.owner_sid
ORDER BY    j.name,
            js.step_id
;
