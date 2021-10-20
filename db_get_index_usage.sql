/* ================================================================================================
Purpose:
    Returns index usage since the last SQL Server restart or database was been attached.
 
History:
    2008-02-20  Tom Hogan           Created.
================================================================================================ */

SELECT      schema_name(o.schema_id)                     AS schema_name,
            o.name                                       AS table_name,
            CASE
                WHEN i.name IS NULL
                    THEN ''
                ELSE i.name
            END                                          AS index_name,
            i.type_desc                                  AS index_type,
            i.is_disabled,
            i.is_hypothetical,
            i.has_filter,
            i.fill_factor,
            s.user_seeks + s.user_scans + s.user_lookups AS total_reads,
            s.user_updates                               AS total_writes
FROM        sys.dm_db_index_usage_stats AS s
JOIN        sys.objects                 AS o    ON  o.object_id = s.object_id
JOIN        sys.indexes                 AS i    ON  i.object_id = s.object_id
                                                AND i.index_id = s.index_id
WHERE       s.database_id = db_id()
ORDER BY    schema_name,
            table_name;
