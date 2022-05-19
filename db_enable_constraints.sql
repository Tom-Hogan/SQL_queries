/* ================================================================================================
Purpose:
    Enables all foreign key constraints, check constraints and triggers.
 
History:
    2006-12-02  Tom Hogan           Created.
    2015-07-22  Tom Hogan           Updated to use sys views.
================================================================================================ */
DECLARE @table_schema    nvarchar(128),
        @table_name      nvarchar(128),
        @constraint_name nvarchar(128),
        @trigger_name    nvarchar(128),
        @constraint_list CURSOR,
        @trigger_list    CURSOR,
        @sql_cmd         nvarchar(4000),
        @debug           tinyint = 0;


/*
    foreign keys and check constraints
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that enables each 
*/
SET @constraint_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    /* check constraints */
    SELECT      quotename(s.name) AS table_schema,
                quotename(o.name) AS table_name,
                quotename(c.name) AS constraint_name
    FROM        sys.check_constraints   AS c
    JOIN        sys.objects             AS o    ON  o.object_id = c.parent_object_id
    JOIN        sys.schemas             AS s    ON  s.schema_id = o.schema_id
    WHERE       c.is_ms_shipped = 0 /* user created */
    UNION
    /* foreign keys */
    SELECT      quotename(s.name)  AS table_schema,
                quotename(o.name)  AS table_name,
                quotename(fk.name) AS constraint_name
    FROM        sys.foreign_keys    AS fk
    JOIN        sys.objects         AS o    ON  o.object_id = fk.parent_object_id
    JOIN        sys.schemas         AS s    ON  s.schema_id = o.schema_id
    WHERE       fk.is_ms_shipped = 0    /* user created */
    ORDER BY    table_schema,
                table_name,
                constraint_name;

OPEN @constraint_list;
FETCH NEXT FROM @constraint_list INTO @table_schema, @table_name, @constraint_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' CHECK CONSTRAINT ' + @constraint_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @constraint_list INTO @table_schema, @table_name, @constraint_name;
END;


/*
    triggers
     - use a cursor to store trigger names
     - work through the cursor to build and execute a statement that enables each 
*/
SET @trigger_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)  AS table_schema,
                quotename(t.name)  AS table_name,
                quotename(tr.name) AS trigger_name
    FROM        sys.triggers    AS tr
    JOIN        sys.objects     AS t    ON  t.object_id = tr.parent_id
    JOIN        sys.schemas     AS s    ON  s.schema_id = t.schema_id
    WHERE       tr.is_ms_shipped = 0    /* user created */
    ORDER BY    s.name,
                t.name,
                tr.name;

OPEN @trigger_list;
FETCH NEXT FROM @trigger_list INTO @table_schema, @table_name, @trigger_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' ENABLE TRIGGER ' + @trigger_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @trigger_list INTO @table_schema, @table_name, @trigger_name;
END;
