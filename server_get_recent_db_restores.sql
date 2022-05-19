/* ================================================================================================
Purpose:
    Lists most recent database restores.
 
History:
    2007-07-10  Tom Hogan           Created.
================================================================================================ */
USE msdb;


SELECT      h.destination_database_name                    AS db_restored,
            convert(varchar(20), h.restore_date, 120)      AS date_restored,
            CASE h.restore_type
                WHEN 'D'
                    THEN 'Database'
                WHEN 'F'
                    THEN 'File'
                WHEN 'G'
                    THEN 'Filegroup'
                WHEN 'I'
                    THEN 'Differential'
                WHEN 'L'
                    THEN 'Log'
                WHEN 'V'
                    THEN 'Verifyonly'
                WHEN 'R'
                    THEN 'Revert'
                ELSE ''
            END                                            AS restore_type,
            CASE h.replace
                WHEN 1
                    THEN 'Yes'
                ELSE 'No'
            END                                            AS overwrite_existing_db,
            s.server_name                                  AS source_server,
            s.database_name                                AS source_db,
            convert(varchar(20), s.backup_start_date, 120) AS source_backup_start,
            h.user_name                                    AS restored_by
FROM        dbo.restorehistory  AS h
JOIN        dbo.backupset       AS s    ON  s.backup_set_id = h.backup_set_id
WHERE       h.restore_date =
                (
                    SELECT  max(hd.restore_date)
                    FROM    dbo.restorehistory AS hd
                    WHERE   hd.destination_database_name = h.destination_database_name
                )
ORDER BY    h.restore_date DESC;
