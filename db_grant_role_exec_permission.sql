/* ================================================================================================
Purpose:
    Grants EXECUTE permissions to ALL stored procedures for a given user / role.
 
History
    2004-11-12  Tom Hogan           Created.
================================================================================================ */

DECLARE @module_schema  nvarchar(128),
        @module_name    nvarchar(128),
        @user_name      nvarchar(128),
        @procedure_list CURSOR,
        @sql_cmd        nvarchar(4000);

SET @user_name = N'my_test_user';


-- ------------------------------------------------------------------------------------------------
-- grant execute permissions for ALL stored procedures to the role
-- ------------------------------------------------------------------------------------------------
-- declare cursor to store the list of stored procs in the database
SET @procedure_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(s.name) AS module_schema,
                quotename(o.name) AS module_name
    FROM        sys.sql_modules AS m
    JOIN        sys.objects     AS o    ON  o.object_id = m.object_id
                                        AND o.is_ms_shipped = 0
                                        AND o.type = 'P' -- procedures
    JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
    ORDER BY    module_schema,
                module_name;

-- open cursor and work through records
OPEN @procedure_list;
FETCH NEXT FROM @procedure_list INTO @module_schema, @module_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    -- build command to grant execute permission and then execute
    SET @sql_cmd = N'GRANT EXECUTE ON ' + @module_schema + N'.' + @module_name + N' TO ' + quotename(@user_name);
    
    EXEC sys.sp_executesql 
        @stmt = @sql_cmd;

    FETCH NEXT FROM @procedure_list INTO @module_schema, @module_name;
END;
