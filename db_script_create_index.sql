/* ================================================================================================
Purpose:
    Outputs CREATE statements for all indexes.

    *** Uncomment and update WHERE clause to filter for a specific table
 
History:
    2011-02-22  Tom Hogan           Created, based on a script by Jamie Thomson.
================================================================================================ */

-- get index data for the table(s) and the columns in those indexes
WITH cte_index_list
AS
    (
    SELECT  ic.index_id + ic.object_id AS index_id,
            schema_name(t.schema_id)   AS table_schema,
            t.name                     AS table_name,
            i.name                     AS index_name,
            c.name                     AS column_name,
            i.type_desc,
            i.is_primary_key,
            i.is_unique,
            ic.key_ordinal             AS column_order,
            ic.is_included_column
    FROM    sys.indexes         AS i
    JOIN    sys.index_columns   AS ic   ON  ic.index_id = i.index_id
                                        AND ic.object_id = i.object_id
    JOIN    sys.columns         AS c    ON  c.column_id = ic.column_id
                                        AND c.object_id = i.object_id
    JOIN    sys.tables          AS t    ON  t.object_id = i.object_id
            -- ------------------------------------------------------------------------------------------------
            -- add filters, if needed
            -- ------------------------------------------------------------------------------------------------
    WHERE   i.is_primary_key = 0
    --AND     t.name = ''
    ),
-- consolidate the column that make up the indexes into one field
cte_indexes
AS
    (
    SELECT  DISTINCT
            i.table_schema,
            i.table_name,
            i.index_name,
            i.type_desc,
            i.is_primary_key,
            i.is_unique,
            stuff((
                  SELECT    ',' + quotename(c.column_name)
                  FROM      cte_index_list  AS c
                  WHERE     c.is_included_column = 0
                  AND       c.index_id = i.index_id
                  ORDER BY  c.column_order
                  FOR XML PATH('')
                  ), 
                  1,
                  1,
                  ''
                 ) AS idx_columns,
            stuff((
                  SELECT    ',' + quotename(c.column_name)
                  FROM      cte_index_list  AS c
                  WHERE     c.is_included_column = 1
                  AND       c.index_id = i.index_id
                  ORDER BY  c.column_order
                  FOR XML PATH('')
                  ),
                  1,
                  1,
                  ''
                 ) AS included_columns
    FROM    cte_index_list  AS i
    )
-- return the create statement
SELECT      'CREATE ' 
                +   CASE
                        WHEN is_unique = 1
                            THEN 'UNIQUE '
                        ELSE ''
                    END 
                + type_desc 
                + ' INDEX ' + quotename(index_name) COLLATE DATABASE_DEFAULT 
                + ' ON ' + quotename(table_schema) 
                + '.' + quotename(table_name) COLLATE DATABASE_DEFAULT 
                + ' (' + idx_columns + ')'
                +   CASE
                        WHEN included_columns IS NOT NULL
                            THEN ' INCLUDE (' + included_columns + ')'
                        ELSE ''
                    END + ';'
FROM        cte_indexes
ORDER BY    table_name,
            is_primary_key DESC,
            type_desc,
            index_name
;
