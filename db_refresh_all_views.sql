/* ================================================================================================
Purpose:
    Refreshes all views.
 
History:
    2016-06-01  Tom Hogan           Created.
================================================================================================ */
DECLARE @table_schema nvarchar(128),
        @table_name   nvarchar(128),
        @view_list    CURSOR,
        @sql_cmd      nvarchar(4000),
        @debug        tinyint = 0;


/*
    use a cursor to store view names
    work through the cursor to build and execute a statement that refreshes each one
*/
SET @view_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS table_schema,
                quotename(o.name) AS table_name
    FROM        sys.objects AS o
    JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
    WHERE       o.is_ms_shipped = 0 /* user created */
    AND         o.type = 'V'        /* views */
    ORDER BY    table_schema,
                table_name;

OPEN @view_list;
FETCH NEXT FROM @view_list INTO @table_schema, @table_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'EXEC sp_refreshview ''' + @table_schema + N'.' + @table_name + N'''';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    PRINT 'Refreshed view: ' + @table_schema + '.' + @table_name;

    FETCH NEXT FROM @view_list INTO @table_schema, @table_name;
END;
