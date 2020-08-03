/* ================================================================================================
Purpose:
    Refreshes all views.
 
History:
    2016-06-01  Tom Hogan           Created.
================================================================================================ */

DECLARE @table_schema nvarchar(128),
        @table_name   nvarchar(128),
        @view_list    CURSOR,
        @sql_cmd      nvarchar(4000);


-- open a cursor to store view names
SET @view_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT      quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name
    FROM        sys.objects AS o
    JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
                -- non-Microsoft objects
    WHERE       o.is_ms_shipped = 0
    AND         o.type = 'V'    -- views
    ORDER BY    table_schema,
                table_name;

-- work through cursor
OPEN @view_list;
FETCH NEXT FROM @view_list INTO @table_schema, @table_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    -- build command to drop view and then execute
    SET @sql_cmd = N'EXEC sp_refreshview ''' + @table_schema + N'.' + @table_name + N'''';

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    PRINT 'Refreshed view: ' + @table_schema + '.' + @table_name;

    FETCH NEXT FROM @view_list INTO @table_schema, @table_name;
END;
