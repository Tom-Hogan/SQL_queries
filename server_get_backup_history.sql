/* ================================================================================================
Purpose:
    Lists history of backups performed over the past 7 days.

    *** Uncomment and update WHERE clause to filter for a specific database.
 
History:
    2012-09-04  Tom Hogan           Created, based on a script by Pinal Dave.
================================================================================================ */
USE master;


SELECT      s.server_name,
            s.database_name,
            s.recovery_model,
            CASE s.type
                WHEN 'D'
                    THEN 'Full'
                WHEN 'I'
                    THEN 'Differential'
                WHEN 'L'
                    THEN 'Log'
                ELSE 'Unknown'
            END                                                         AS backup_type,
            s.backup_finish_date,
            m.physical_device_name,
            cast(s.backup_size / 1024 / 1024 AS int)                    AS backup_size_in_MB,
            datediff(MINUTE, s.backup_start_date, s.backup_finish_date) AS backup_time_in_min,
            s.is_copy_only
FROM        msdb.dbo.backupset          AS s
JOIN        msdb.dbo.backupmediafamily  AS m    ON  m.media_set_id = s.media_set_id
            -- get past 7 day's worth of backups
WHERE       s.backup_start_date >= dateadd("day", -7, getdate())
            -- ------------------------------------------------------------------------------------------------
            -- to get specific database
            -- ------------------------------------------------------------------------------------------------
--AND         s.database_name = 'database_name'
ORDER BY    s.database_name,
            s.backup_finish_date DESC
;
