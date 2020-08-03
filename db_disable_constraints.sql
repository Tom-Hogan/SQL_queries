/* ================================================================================================
Purpose:
    Disables all foreign key, check constraints and triggers.
 
History:
    2006-12-02  Tom Hogan           Created.
    2015-07-22  Tom Hogan           Updated to use sys views.
================================================================================================ */

DECLARE @table_schema    nvarchar(128),
        @table_name      nvarchar(128),
        @fk_name         nvarchar(128),
        @trigger_name    nvarchar(128),
        @constraint_list CURSOR,
        @trigger_list    CURSOR,
        @sql_cmd         nvarchar(4000);


-- ------------------------------------------------------------------------------------------------
-- foreign keys & check constraints
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store FK names
SET @constraint_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    -- check constraints
    SELECT      DISTINCT
                quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name,
                quotename(c.name)   AS constraint_name
    FROM        sys.check_constraints   AS c
    JOIN        sys.objects             AS o    ON  o.object_id = c.parent_object_id
    JOIN        sys.schemas             AS s    ON  s.schema_id = o.schema_id
                -- get non-Microsoft objects
    WHERE       c.is_ms_shipped = 0
    UNION ALL
    -- foreign keys
    SELECT      DISTINCT
                quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name,
                quotename(fk.name)  AS constraint_name
    FROM        sys.foreign_keys    AS fk
    JOIN        sys.objects         AS o    ON  o.object_id = fk.parent_object_id
    JOIN        sys.schemas         AS s    ON  s.schema_id = o.schema_id
                -- get non-Microsoft objects
    WHERE       fk.is_ms_shipped = 0
    ORDER BY    table_schema,
                table_name,
                constraint_name;

-- work through cursor
-- build command to disable constraint and then execute
OPEN @constraint_list;
FETCH NEXT FROM @constraint_list INTO @table_schema, @table_name, @fk_name; 

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' NOCHECK CONSTRAINT ' + @fk_name;

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @constraint_list INTO @table_schema, @table_name, @fk_name;
END;


-- ------------------------------------------------------------------------------------------------
-- triggers
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store trigger names
SET @trigger_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT      quotename(s.name)   AS table_schema,
                quotename(t.name)   AS table_name,
                quotename(tr.name)  AS trigger_name
    FROM        sys.triggers    AS tr
    JOIN        sys.objects     AS t    ON  t.object_id = tr.parent_id
    JOIN        sys.schemas     AS s    ON  s.schema_id = t.schema_id
                -- get non-Microsoft objects
    WHERE       tr.is_ms_shipped = 0
    ORDER BY    s.name,
                t.name,
                tr.name;


-- work through cursor
-- build command to disable trigger and then execute
OPEN @trigger_list;
FETCH NEXT FROM @trigger_list INTO @table_schema, @table_name, @trigger_name;
WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' DISABLE TRIGGER ' + @trigger_name;
    
    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @trigger_list INTO @table_schema, @table_name, @trigger_name;
END;
