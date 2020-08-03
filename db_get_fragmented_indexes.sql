/* ================================================================================================
Purpose:
    Returns indexes that are at least 30% fragmented and recommends what type of defragmenting 
    should be performed.

    *** This could take a long time to run.
 
History:
    2008-05-29  Tom Hogan           Created.
================================================================================================ */

SELECT      d.name                                   AS database_name,
            o.name                                   AS table_name,
            i.name                                   AS index_name,
            s.page_count,
            round(s.avg_fragmentation_in_percent, 2) AS avg_fragmentation_in_percent,
            CASE
                WHEN s.avg_fragmentation_in_percent > 50
                    THEN 'Rebuild'
                WHEN s.avg_fragmentation_in_percent > 30
                    THEN 'Reorganize'
                ELSE 'No Action'
            END                                      AS index_needs
FROM        sys.dm_db_index_physical_stats(db_id(), object_id(NULL), NULL, NULL, 'DETAILED') AS s
JOIN        sys.indexes     AS i    ON  i.object_id = s.object_id
                                    AND i.index_id = s.index_id
JOIN        sys.databases   AS d    ON  d.database_id = s.database_id
JOIN        sys.objects     AS o    ON  o.object_id = s.object_id
                                    AND o.type IN ('U', 'V')    -- user tables & views
WHERE       s.avg_fragmentation_in_percent > 30
AND         s.page_count > 1000
ORDER BY    d.name,
            o.name,
            i.name
;
