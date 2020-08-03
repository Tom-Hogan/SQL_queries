/* ================================================================================================
Purpose:
    Returns tables, columns, column type, NULL option and if column is part of a PK/FK constraint.

    *** Uncomment the "Profile the table column" section if you want some metrics about the values
        stored in the tables.  This will take a long time to run.

History:
    2004-11-12  Tom Hogan           Created.
    2013-05-15  Tom Hogan           - Changed to use sys tables.
                                    - Added option to get record values.
================================================================================================ */
SET NOCOUNT ON;

DECLARE @table_schema nvarchar(128),
        @table_name   nvarchar(128),
        @column_name  nvarchar(128),
        @data_type    nvarchar(128),
        @column_list  CURSOR,
        @sql_cmd      nvarchar(4000);

-- create a temp table to table information
DROP TABLE IF EXISTS #table_schema;
DROP TABLE IF EXISTS #value_counts;

CREATE TABLE #table_schema (
    table_schema        nvarchar(128) NOT NULL,
    table_name          nvarchar(128) NOT NULL,
    column_name         nvarchar(128) NOT NULL,
    data_type           nvarchar(128) NOT NULL,
    length_or_precision varchar(10)   NOT NULL,
    allows_null         char(1)       NOT NULL,
    default_value       varchar(1000) NOT NULL,
    pk_flag             char(1)       NOT NULL,
    fk_flag             char(1)       NOT NULL,
    column_position     int           NOT NULL
);

-- create temp table to hold row value results
CREATE TABLE #value_counts (
    table_schema    nvarchar(128) NOT NULL,
    table_name      nvarchar(128) NOT NULL,
    column_name     nvarchar(128) NOT NULL,
    row_count       int           NULL,
    distinct_values int           NULL,
    empty_values    int           NULL
);


-- ------------------------------------------------------------------------------------------------
-- load schema information for given table(s)
-- ------------------------------------------------------------------------------------------------
INSERT INTO #table_schema (
            table_schema,
            table_name,
            column_name,
            data_type,
            length_or_precision,
            allows_null,
            default_value,
            pk_flag,
            fk_flag,
            column_position
)
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
            CASE
                WHEN pk.column_id IS NOT NULL
                    THEN 'Y'
                ELSE 'N'
            END                                                AS pk_flag,
            CASE
                WHEN fk.column_id IS NOT NULL
                    THEN 'Y'
                ELSE 'N'
            END                                                AS fk_flag,
            c.column_id                                        AS column_position
FROM        sys.columns AS c
JOIN        sys.objects AS o    ON  o.object_id = c.object_id
JOIN        sys.types   AS t    ON  t.user_type_id = c.user_type_id
JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
            -- get primary key
LEFT JOIN   (
            SELECT  ic2.object_id AS table_id,
                    ic2.column_id
            FROM    sys.indexes         AS i2
            JOIN    sys.index_columns   AS ic2  ON  ic2.object_id = i2.object_id
                                                AND ic2.index_id = i2.index_id
            JOIN    sys.columns         AS c2   ON  c2.object_id = ic2.object_id
                                                AND c2.column_id = ic2.column_id
            WHERE   i2.is_primary_key = 1
            )           AS pk   ON  pk.table_id = o.object_id
                                AND pk.column_id = c.column_id
            -- get foreign key(s)
LEFT JOIN   (
            SELECT  fkcol.object_id AS table_id,
                    fkcol.column_id
            FROM    sys.foreign_key_columns AS fkc
            JOIN    sys.columns             AS fkcol    ON  fkcol.object_id = fkc.parent_object_id
                                                        AND fkcol.column_id = fkc.parent_column_id
            )           AS fk   ON  fk.table_id = o.object_id
                                AND fk.column_id = c.column_id
WHERE       o.type = 'U'    -- U = user table, V = view
ORDER BY    o.name,
            c.column_id;


/*
-- ------------------------------------------------------------------------------------------------
-- profile the table columns
-- ------------------------------------------------------------------------------------------------
-- store table and column names in a cursor
SET @column_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR
SELECT  table_schema,
        table_name,
        column_name,
        data_type
FROM    #table_schema;


-- loop through columns to get value counts
OPEN @column_list;
FETCH NEXT FROM @column_list INTO @table_schema, @table_name, @column_name, @data_type;

WHILE ( @@fetch_status = 0 )
BEGIN
    PRINT @table_name + ' - ' + @column_name;

    SET @sql_cmd = N'SELECT  ''';

    -- count empty strings as NULLs for string data types
    IF @data_type IN ('varchar', 'nvarchar', 'char', 'nchar')
    BEGIN
        SET @sql_cmd =
            @sql_cmd + @table_schema + N''',
        '''            + @table_name + N''',
        '''            + @column_name
            + N''',
        count(*)    AS row_count,
        count(DISTINCT
                    CASE 
                        WHEN ' + quotename(@column_name) + N'= ''''
                            THEN NULL 
                        ELSE ' + quotename(@column_name) + N'
                    END)        AS distinct_values,
        sum(CASE
                WHEN ' + quotename(@column_name) + N' IS NULL THEN 1
                WHEN ' + quotename(@column_name) + N' = '''' THEN 1
                ELSE 0
            END )   AS empty_values
FROM    '              + quotename(@table_schema) + N'.' + quotename(@table_name) + N' WITH (NOLOCK)';
    END;
    -- ignore counts for XML data type
    ELSE IF @data_type IN ('xml')
    BEGIN
        SET @sql_cmd = @sql_cmd + @table_schema + N''',
        '''            + @table_name + N''',
        '''            + @column_name + N''',
        sum(0)  AS row_count,
        sum(0)  AS distinct_values,
        sum(0)  AS empty_values
FROM    '              + quotename(@table_schema) + N'.' + quotename(@table_name) + N' WITH (NOLOCK)';
    END;
    ELSE
    BEGIN
        SET @sql_cmd = @sql_cmd + @table_schema + N''',
        '''            + @table_name + N''',
        '''            + @column_name + N''',
        count(*)    AS row_count,
        count(DISTINCT ' + quotename(@column_name) + N')    AS distinct_values,
        sum(CASE
                WHEN ' + quotename(@column_name) + N' IS NULL THEN 1
                ELSE 0
            END )   AS empty_values
FROM    '              + quotename(@table_schema) + N'.' + quotename(@table_name) + N' WITH (NOLOCK)';
    END;

    INSERT INTO #value_counts (
                table_schema,
                table_name,
                column_name,
                row_count,
                distinct_values,
                empty_values
    )
    EXEC        ( @sql_cmd );

    FETCH NEXT FROM @column_list INTO @table_schema, @table_name, @column_name, @data_type;
END;
*/

-- ------------------------------------------------------------------------------------------------
-- return results
-- ------------------------------------------------------------------------------------------------
SELECT      s.table_schema,
            s.table_name,
            s.column_name,
            s.data_type,
            s.length_or_precision,
            s.allows_null,
            replace(replace(s.default_value, char(10), ''), char(13), '') AS default_value,
            s.pk_flag,
            s.fk_flag,
            CASE
                WHEN s.data_type = 'xml'
                    THEN NULL
                ELSE v.row_count
            END                                                            AS row_count,
            CASE
                WHEN s.data_type = 'xml'
                    THEN NULL
                ELSE v.distinct_values
            END                                                            AS distinct_values,
            CASE
                WHEN s.data_type = 'xml'
                    THEN NULL
                ELSE v.empty_values
            END                                                            AS empty_values
FROM        #table_schema   AS s
LEFT JOIN   #value_counts   AS v    ON  v.table_schema = s.table_schema
                                    AND v.table_name = s.table_name
                                    AND v.column_name = s.column_name
ORDER BY    s.table_schema,
            s.table_name,
            s.column_position
;
