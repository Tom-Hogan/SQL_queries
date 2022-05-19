/* ================================================================================================
Purpose:
    Returns indexes that have not been used since the last SQL Server restart or database was attached.
 
History:
    2008-02-20  Tom Hogan           Created, based on script by Pinal Dave (C) 2011.
================================================================================================ */
SELECT      TOP ( 25 )
            o.name                                              AS table_name,
            i.name                                              AS index_name,
            i.index_id,
            ius.user_seeks,
            ius.user_scans,
            ius.user_lookups,
            ius.user_updates,
            p.table_rows,
            'DROP INDEX ' + quotename(i.name) 
                + ' ON ' + quotename(s.name) 
                + '.' + quotename(object_name(ius.object_id))   AS drop_statement
FROM        sys.dm_db_index_usage_stats AS ius
JOIN        sys.indexes                 AS i    ON  i.index_id = ius.index_id
                                                AND i.object_id = ius.object_id
JOIN        sys.objects                 AS o    ON  o.object_id = ius.object_id
JOIN        sys.schemas                 AS s    ON  s.schema_id = o.schema_id
JOIN        (
                SELECT      sum(p2.rows) AS table_rows,
                            p2.index_id,
                            p2.object_id
                FROM        sys.partitions AS p2
                GROUP BY    p2.index_id,
                            p2.object_id
            )                           AS p    ON  p.index_id = ius.index_id
                                                AND p.object_id = ius.object_id
WHERE       ius.database_id = db_id()
AND         i.type_desc = 'nonclustered'
AND         i.is_primary_key = 0
AND         i.is_unique_constraint = 0
ORDER BY    ( ius.user_seeks + ius.user_scans + ius.user_lookups ),
            o.name,
            i.name;
