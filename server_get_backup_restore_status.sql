/* ================================================================================================
Purpose:
    Lists status of database backups / restores currently running.
 
History:
    2012-05-06  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      r.session_id                                                   AS spid,
            r.command,
            t.text                                                         AS query,
            r.start_time,
            cast(r.percent_complete AS decimal(6, 2))                      AS percent_complete,
            dateadd(SECOND, r.estimated_completion_time / 1000, getdate()) AS estimated_completion_time
FROM        sys.dm_exec_requests                AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)  AS t
WHERE       r.command IN ('BACKUP DATABASE', 'RESTORE DATABASE');
