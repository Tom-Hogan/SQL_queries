/* ================================================================================================
Purpose:
    Returns index details.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific table.
 
History:
    2010-10-14  Tom Hogan           Created, based on a script by Jamie Thomson.
================================================================================================ */
WITH
cte_index_list AS
(
    SELECT      ic.index_id + ic.object_id AS index_id,
                t.name                     AS table_name,
                i.name                     AS index_name,
                c.name                     AS column_name,
                i.type_desc,
                i.is_primary_key,
                i.is_unique,
                ic.key_ordinal             AS column_order,
                ic.is_included_column,
                rc.row_count
    FROM        sys.indexes         AS i
    JOIN        sys.index_columns   AS ic   ON  ic.index_id = i.index_id
                                            AND ic.object_id = i.object_id
    JOIN        sys.columns         AS c    ON  c.column_id = ic.column_id
                                            AND c.object_id = i.object_id
    JOIN        sys.tables          AS t    ON  t.object_id = i.object_id
                                            AND t.is_ms_shipped = 0 /* user created */
    LEFT JOIN   (
                    SELECT      p.object_id,
                                p.index_id,
                                sum(p.rows) AS row_count
                    FROM        sys.partitions  AS p
                    GROUP BY    p.object_id,
                                p.index_id
                )                   AS rc   ON  rc.object_id = i.object_id
                                            AND rc.index_id = i.index_id
                /*
                === to get specific table ===
                */
    --WHERE       t.name = ''
)
SELECT      DISTINCT
            i.table_name,
            i.index_name,
            i.type_desc,
            i.is_primary_key,
            i.is_unique,
            i.row_count,
            stuff(
            (
                SELECT      ',' + c.column_name
                FROM        cte_index_list  AS c
                WHERE       c.is_included_column = 0
                AND         c.index_id = i.index_id
                ORDER BY    c.column_order
                FOR XML PATH('')
            ),
            1,
            1,
            ''
                 ) AS idx_columns,
            stuff(
            (
                SELECT      ',' + c.column_name
                FROM        cte_index_list  AS c
                WHERE       c.is_included_column = 1
                AND         c.index_id = i.index_id
                ORDER BY    c.column_order
                FOR XML PATH('')
            ),
            1,
            1,
            ''
                 ) AS included_columns
FROM        cte_index_list AS i
ORDER BY    i.table_name,
            i.type_desc,
            i.index_name;
