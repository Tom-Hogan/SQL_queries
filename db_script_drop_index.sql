/* ================================================================================================
Purpose:
    Outputs DROP statements for all indexes.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific table.
 
History:
    2011-02-22  Tom Hogan           Created, based on a script by Jamie Thomson.
================================================================================================ */
/* get index data for the table(s) and the columns in those indexes */
WITH
cte_index_list AS
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
            /*
            === to get specific table ===
            */
    --WHERE   t.name = ''
),
/* get distinct list of indexes */
cte_indexes AS
(
    SELECT  DISTINCT
            i.table_schema,
            i.table_name,
            i.index_name,
            i.type_desc,
            i.is_primary_key
    FROM    cte_index_list AS i
)
/* return the drop statement */
SELECT      'DROP INDEX ' 
                + quotename(i.index_name)COLLATE DATABASE_DEFAULT
                + ' ON ' + quotename(i.table_schema) + '.'
                + quotename(i.table_name)COLLATE DATABASE_DEFAULT + ';'
FROM        cte_indexes AS i
ORDER BY    i.table_name,
            i.is_primary_key DESC,
            i.type_desc DESC,
            i.index_name;
