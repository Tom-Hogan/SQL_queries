/* ================================================================================================
Purpose:
    Lists most recent backup for each database.
 
History:
    2017-01-18  Tom Hogan           Created.
================================================================================================ */
USE master;


WITH
cte_backups AS
(
    SELECT      database_name,
                CASE type
                    WHEN 'D'
                        THEN 'Database'
                    WHEN 'I'
                        THEN 'Differential database'
                    WHEN 'L'
                        THEN 'Log'
                    WHEN 'F'
                        THEN 'File'
                    WHEN 'G'
                        THEN 'Differential file'
                    WHEN 'P'
                        THEN 'Partial'
                    WHEN 'Q'
                        THEN 'Differential partial'
                    ELSE 'Other'
                END                     AS backup_type,
                max(backup_finish_date) AS backup_finish_date
    FROM        msdb.dbo.backupset
    GROUP BY    database_name,
                type
)
SELECT      @@servername          AS server_name,
            d.name                AS database_name,
            d.recovery_model_desc AS recovery_model,
            d.state_desc,
            b.backup_type,
            b.backup_finish_date
FROM        sys.databases   AS d
LEFT JOIN   cte_backups     AS b    ON  b.database_name = d.name
WHERE       d.name <> 'tempdb'
AND         d.state_desc <> 'OFFLINE'
ORDER BY    d.name,
            b.backup_type;
