/* ================================================================================================
Purpose:
    Returns recommended indexes based on the missing index DMV.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific table.
 
History:
    2015-11-10  Tom Hogan           Created, based on a script by Pinal Dave (C) 2011.
================================================================================================ */

WITH
cte_details AS
(
    SELECT  mid.database_id,
            ( migs.avg_user_impact * ( migs.user_seeks + migs.user_scans ))     AS average_estimated_impact,
            migs.last_user_seek,
            object_name(mid.object_id, mid.database_id)                         AS table_name,
            'CREATE INDEX [IX_' + object_name(mid.object_id, mid.database_id) 
                + '_'
                + replace(replace(replace(isnull(mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') 
                +   CASE
                        WHEN mid.equality_columns IS NOT NULL
                        AND  mid.inequality_columns IS NOT NULL
                            THEN '_'
                        ELSE ''
                    END
                + replace(replace(replace(isnull(mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']' 
                + ' ON ' 
                + mid.statement + ' (' 
                + isnull(mid.equality_columns, '')
                +   CASE
                        WHEN mid.equality_columns IS NOT NULL
                        AND  mid.inequality_columns IS NOT NULL
                            THEN ','
                        ELSE ''
                    END 
                + isnull(mid.inequality_columns, '') + ')' 
                + isnull(' INCLUDE (' + mid.included_columns + ')', '')         AS create_index_statement
    FROM    sys.dm_db_missing_index_groups      AS mig
    JOIN    sys.dm_db_missing_index_group_stats AS migs ON  migs.group_handle = mig.index_group_handle
    JOIN    sys.dm_db_missing_index_details     AS mid  ON  mid.index_handle = mig.index_handle
    WHERE   mid.database_id = db_id()
)
SELECT      d.database_id,
            d.average_estimated_impact,
            d.last_user_seek,
            d.table_name,
            d.create_index_statement
FROM        cte_details AS d
            /*
            === to get specific table ===
            */
WHERE       d.table_name = ''
ORDER BY    d.average_estimated_impact DESC;
