/* ================================================================================================
Purpose:
    Returns column information.
    
Notes:
    Contains commented out predefined AND in the WHERE clause to filter results for a specific table.
 
History:
    2004-12-06  Tom Hogan           Created.
    2015-07-21  Tom Hogan           Updated to include datetime precision.
================================================================================================ */
SELECT      s.name                                             AS table_schema,
            cast(o.name AS nvarchar(128))                      AS table_name,
            cast(c.name AS nvarchar(128))                      AS column_name,
            cast(t.name AS nvarchar(128))                      AS data_type,
            CASE
                WHEN t.name IN ('varchar', 'char', 'nvarchar', 'nchar')
                AND  c.max_length = -1
                    THEN 'max'
                WHEN t.name IN ('nvarchar', 'nchar')
                    THEN cast(( c.max_length / 2 ) AS varchar(4))
                WHEN c.precision > 0
                    THEN cast(c.precision AS varchar(4)) + isnull(', ' + cast(c.scale AS varchar(4)), '')
                ELSE cast(c.max_length AS varchar(4))
            END                                                AS length_or_precision,
            CASE
                WHEN c.is_nullable = 1
                    THEN 'Y'
                ELSE 'N'
            END                                                AS allows_null,
            isnull(object_definition(c.default_object_id), '') AS default_value,
            c.column_id                                        AS position,
            o.type_desc                                        AS object_type
FROM        sys.columns AS c
JOIN        sys.objects AS o    ON  o.object_id = c.object_id
JOIN        sys.types   AS t    ON  t.user_type_id = c.user_type_id
JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
WHERE       o.type = 'U'    /* U = user table, V = view */
            /*
            === to get specific table ===
            */
--AND         o.name = ''
ORDER BY    table_schema,
            table_name,
            position;
