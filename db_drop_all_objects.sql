/* ================================================================================================
Purpose:
    Drops all objects in a database.

    *** Update database name.
 
History:
    2006-11-14  Tom Hogan           Created.
    2010-11-01  Tom Hogan           Added synonyms.
    2015-07-22  Tom Hogan           Updated to use sys views.
================================================================================================ */
USE ?;      -- update with database name to have ALL objects dropped


DECLARE @table_schema     nvarchar(128),
        @table_name       nvarchar(128),
        @fk_name          nvarchar(128),
        @module_name      nvarchar(128),
        @synonym_name     nvarchar(128),
        @foreign_key_list CURSOR,
        @view_list        CURSOR,
        @table_list       CURSOR,
        @procedure_list   CURSOR,
        @function_list    CURSOR,
        @synonym_list     CURSOR,
        @sql_cmd          nvarchar(4000);


-- ------------------------------------------------------------------------------------------------
-- foreign keys
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store FK names
SET @foreign_key_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name,
                quotename(fk.name)  AS constraint_name
    FROM        sys.foreign_keys    AS fk
    JOIN        sys.objects         AS o    ON  o.object_id = fk.parent_object_id
                                                -- get non-Microsoft objects
                                            AND o.is_ms_shipped = 0
    JOIN        sys.schemas         AS s    ON  s.schema_id = o.schema_id
                -- get non-Microsoft objects
    WHERE       fk.is_ms_shipped = 0
    ORDER BY    table_schema,
                table_name,
                constraint_name;

-- work through cursor
-- build command to drop foreign key and then execute    
OPEN @foreign_key_list;
FETCH NEXT FROM @foreign_key_list INTO @table_schema, @table_name, @fk_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' DROP CONSTRAINT ' + @fk_name;

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @foreign_key_list INTO @table_schema, @table_name, @fk_name;
END;


-- ------------------------------------------------------------------------------------------------
-- views
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store view names
SET @view_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name
    FROM        sys.objects AS o
    JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
                -- get non-Microsoft objects
    WHERE       o.is_ms_shipped = 0
    AND         o.type = 'V'    -- views
    ORDER BY    table_schema,
                table_name;

-- work through cursor
-- build command to drop view key and then execute
OPEN @view_list;
FETCH NEXT FROM @view_list INTO @table_schema, @table_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP VIEW ' + @table_schema + N'.' + @table_name;

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @view_list INTO @table_schema, @table_name;
END;


-- ------------------------------------------------------------------------------------------------
-- tables
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store table names
SET @table_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)   AS table_schema,
                quotename(o.name)   AS table_name
    FROM        sys.objects AS o
    JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
                -- get non-Microsoft objects
    WHERE       o.is_ms_shipped = 0
    AND         o.type = 'U'    -- user tables
    ORDER BY    table_schema,
                table_name;

-- work through cursor
-- build command to drop table and then execute
OPEN @table_list;
FETCH NEXT FROM @table_list INTO @table_schema, @table_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP TABLE ' + @table_schema + N'.' + @table_name;

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @table_list INTO @table_schema, @table_name;
END;


-- ------------------------------------------------------------------------------------------------
-- procedures
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store procedure names
SET @procedure_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)   AS module_schema,
                quotename(o.name)   AS module_name
    FROM        sys.sql_modules AS sm
    JOIN        sys.objects     AS o    ON  o.object_id = sm.object_id
                                            -- get non-Microsoft procedures
                                        AND o.is_ms_shipped = 0
                                        AND o.type = 'P'
    JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
    ORDER BY    module_schema,
                module_name;

-- work through cursor
-- build command to drop procedure and then execute
OPEN @procedure_list;
FETCH NEXT FROM @procedure_list INTO @table_schema, @module_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP PROCEDURE ' + @table_schema + N'.' + @module_name;
    
    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @procedure_list INTO @table_schema, @module_name;
END;


-- ------------------------------------------------------------------------------------------------
-- functions
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store function names
SET @function_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS module_schema,
                quotename(o.name) AS module_name
    FROM        sys.sql_modules AS sm
    JOIN        sys.objects     AS o    ON  o.object_id = sm.object_id
                                            -- get non-Microsoft functions
                                        AND o.is_ms_shipped = 0
                                        AND o.type IN ('FN', 'IF', 'TF')
    JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
    ORDER BY    module_schema,
                module_name;

-- work through cursor
-- build command to drop function and then execute
OPEN @function_list;
FETCH NEXT FROM @function_list INTO @table_schema, @module_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP FUNCTION ' + @table_schema + N'.' + @module_name;
    
    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @function_list INTO @table_schema, @module_name;
END;


-- ------------------------------------------------------------------------------------------------
-- synonyms
-- ------------------------------------------------------------------------------------------------
-- open a cursor to store synonyms
SET @synonym_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(schema_name(schema_id)) + '.' + quotename(name)
    FROM        sys.synonyms
    ORDER BY    schema_name(schema_id),
                name;

-- work through cursor
-- build command to drop synonym and then execute    
OPEN @synonym_list;
FETCH NEXT FROM @synonym_list INTO @synonym_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP SYNONYM ' + @synonym_name;

    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @synonym_list INTO @synonym_name;
END;
