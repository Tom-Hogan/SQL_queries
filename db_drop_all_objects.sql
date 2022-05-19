/* ================================================================================================
Purpose:
    Drops all objects in a database.  By ALL we mean: tables, views, procedures, functions, and synonyms.

Notes
    Update database name.
 
History:
    2006-11-14  Tom Hogan           Created.
    2010-11-01  Tom Hogan           Added synonyms.
    2015-07-22  Tom Hogan           Updated to use sys views.
================================================================================================ */
USE ?;      /* update with database name to have ALL objects dropped */


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
        @sql_cmd          nvarchar(4000),
        @debug            tinyint = 0;


/*
    foreign keys
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
*/
SET @foreign_key_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name)  AS table_schema,
                quotename(o.name)  AS table_name,
                quotename(fk.name) AS constraint_name
    FROM        sys.foreign_keys    AS fk
    JOIN        sys.objects         AS o    ON  o.object_id = fk.parent_object_id
                                            AND o.is_ms_shipped = 0 /* user created */
    JOIN        sys.schemas         AS s    ON  s.schema_id = o.schema_id
    WHERE       fk.is_ms_shipped = 0    /* user created */
    ORDER BY    table_schema,
                table_name,
                constraint_name;

OPEN @foreign_key_list;
FETCH NEXT FROM @foreign_key_list INTO @table_schema, @table_name, @fk_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'ALTER TABLE ' + @table_schema + N'.' + @table_name + N' DROP CONSTRAINT ' + @fk_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @foreign_key_list INTO @table_schema, @table_name, @fk_name;
END;


/*
    views
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
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
    SET @sql_cmd = N'DROP VIEW ' + @table_schema + N'.' + @table_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @view_list INTO @table_schema, @table_name;
END;


/*
    tables
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
*/
SET @table_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS table_schema,
                quotename(o.name) AS table_name
    FROM        sys.objects AS o
    JOIN        sys.schemas AS s    ON  s.schema_id = o.schema_id
    WHERE       o.is_ms_shipped = 0 /* user created */
    AND         o.type = 'U'        /* user tables */
    ORDER BY    table_schema,
                table_name;

OPEN @table_list;
FETCH NEXT FROM @table_list INTO @table_schema, @table_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP TABLE ' + @table_schema + N'.' + @table_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @table_list INTO @table_schema, @table_name;
END;


/*
    stored procedures
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
*/
SET @procedure_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS module_schema,
                quotename(o.name) AS module_name
    FROM        sys.sql_modules AS sm
    JOIN        sys.objects     AS o    ON  o.object_id = sm.object_id
                                        AND o.is_ms_shipped = 0 /* user created */
                                        AND o.type = 'P'        /* procedures */
    JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
    ORDER BY    module_schema,
                module_name;

OPEN @procedure_list;
FETCH NEXT FROM @procedure_list INTO @table_schema, @module_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP PROCEDURE ' + @table_schema + N'.' + @module_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @procedure_list INTO @table_schema, @module_name;
END;


/*
    functions
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
*/
SET @function_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS module_schema,
                quotename(o.name) AS module_name
    FROM        sys.sql_modules AS sm
    JOIN        sys.objects     AS o    ON  o.object_id = sm.object_id
                                        AND o.is_ms_shipped = 0             /* user created */
                                        AND o.type IN ('FN', 'IF', 'TF')    /* functions */
    JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
    ORDER BY    module_schema,
                module_name;

OPEN @function_list;
FETCH NEXT FROM @function_list INTO @table_schema, @module_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP FUNCTION ' + @table_schema + N'.' + @module_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @function_list INTO @table_schema, @module_name;
END;


/*
    synonyms
     - use a cursor to store their names
     - work through the cursor to build and execute a statement that drops each 
*/
SET @synonym_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(schema_name(schema_id)) + '.' + quotename(name)
    FROM        sys.synonyms
    ORDER BY    schema_name(schema_id),
                name;

OPEN @synonym_list;
FETCH NEXT FROM @synonym_list INTO @synonym_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'DROP SYNONYM ' + @synonym_name + N';';

    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @synonym_list INTO @synonym_name;
END;
