/* ================================================================================================
Purpose:
    Lists history of backups performed over the past 7 days.

Notes:
    Contains commented out predefined AND in the WHERE clause to filter results for a specific database.
 
History:
    2012-09-04  Tom Hogan           Created, based on a script by Pinal Dave.
================================================================================================ */
USE msdb;


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
                WHEN 'F'
                    THEN 'File/Filegroup'
                WHEN 'G'
                    THEN 'Differential File'
                WHEN 'Q'
                    THEN 'Differential Partial'
                WHEN 'P'
                    THEN 'Partial'
                ELSE ''
            END                                                         AS backup_type,
            s.backup_finish_date,
            isnull(s.name, '')                                          AS backup_set_name,
            m.physical_device_name,
            CASE
                WHEN m.device_type = 2
                    THEN 'Disk'
                WHEN m.device_type = 5
                    THEN 'Tape'
                WHEN m.device_type = 7
                    THEN 'Virtual'
                WHEN m.device_type = 9
                    THEN 'Azure Storage'
                WHEN m.device_type = 105
                    THEN 'Disk'
                ELSE ''
            END                                                         AS device_type,
            cast(s.backup_size / 1024 / 1024 AS int)                    AS backup_size_in_MB,
            datediff(MINUTE, s.backup_start_date, s.backup_finish_date) AS backup_time_in_min,
            s.user_name                                                 AS run_by,
            s.is_snapshot,
            s.is_copy_only
FROM        dbo.backupset           AS s
JOIN        dbo.backupmediafamily   AS m    ON  m.media_set_id = s.media_set_id
            /* get past 7 day's worth of backups */
WHERE       s.backup_start_date >= dateadd(DAY, -7, getdate())
            /*
            === to get specific database ===
            */
--AND         s.database_name = 'database_name'
ORDER BY    s.database_name,
            s.backup_finish_date DESC;
