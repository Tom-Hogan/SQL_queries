/* ================================================================================================
Purpose:
    Returns the number of levels for each index as well as page / row counts.
 
History:
    2011-04-22  Tom Hogan           Created, based on a script by David Durant.
    2016-01-06  Tom Hogan           Updated to include partition and row counts.
================================================================================================ */

SELECT      schema_name(o.schema_id) AS table_schema,
            o.name                   AS table_name,
            i.name                   AS index_name,
            i.type_desc              AS index_type,
            s.index_depth,
            p.partition_count,
            p.rows_count,
            s.page_count,
            CASE
                WHEN s.page_count = 0
                    THEN 0
                ELSE p.rows_count / s.page_count
            END                      AS rows_per_page
FROM        sys.dm_db_index_physical_stats(db_id(), object_id(NULL), NULL, NULL, NULL) AS s
JOIN        sys.indexes AS i    ON  i.object_id = s.object_id
                                AND i.index_id = s.index_id
JOIN        sys.objects AS o    ON  o.object_id = i.object_id
                                AND o.type IN ('U', 'V') -- user tables & views
JOIN        (
            SELECT      object_id,
                        index_id,
                        max(partition_number) AS partition_count,
                        sum(rows)             AS rows_count
            FROM        sys.partitions
            GROUP BY    object_id,
                        index_id
            )           AS p    ON  p.object_id = i.object_id
                                AND p.index_id = i.index_id
ORDER BY    table_name,
            table_schema,
            index_name,
            s.index_depth
;
