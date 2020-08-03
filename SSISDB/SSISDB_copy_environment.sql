/* ================================================================================================
Purpose:
    Outputs a script that will create an Integration Services Catalog environment and its associated 
    variables based on an existing ISC environment.

History:
    2017-09-01  Tom Hogan           Created.
================================================================================================ */
USE SSISDB; 
SET NOCOUNT ON;
 
DECLARE @folder_name      nvarchar(128),
        @environment_name nvarchar(128),
        @name             nvarchar(128),
        @type             nvarchar(128),
        @description      nvarchar(1024),
        @value            sql_variant,
        @sensitive        bit,
        @sql_cmd          nvarchar(MAX),
        @variable_list    CURSOR;


SET @folder_name        = 'folder_name';    -- update with folder name that contains environment to copy
SET @environment_name   = 'Dev';            -- update with environment name to be copied


-- ------------------------------------------------------------------------------------------------
-- build script output
-- ------------------------------------------------------------------------------------------------
--  variables
SET @sql_cmd = cast('' AS nvarchar(MAX)) + N'
/* ================================================================================================
This script was generated to create a new SSIS catalog environment from an old one.

*** Change the values as appropriate for the new environment.  The environment variable values can 
    be found in the variable SET statement just above the call to the create environment variable
    procedure call.
    
    Sensitive and NULL values have been replaced with <Placeholder>.  You will need to update 
    with actual value
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


DECLARE @new_folder_name        nvarchar(128),
        @new_environment_name   nvarchar(128),
        @new_folder_id          bigint,
        @new_environment_id     bigint,
        @new_value              sql_variant;


-- *******************************
-- set your new folder and environment names
-- *******************************
SET @new_folder_name        = N''' + @folder_name + ''';
SET @new_environment_name   = N''' + @environment_name + ''';' + char(13) + char(10) + char(13) + char(10);

PRINT @sql_cmd;


--  folder
SET @sql_cmd = N'
-- create folder if it doesn''t exist
IF NOT EXISTS ( SELECT 1 FROM catalog.folders WHERE name = @new_folder_name )
BEGIN
    EXEC catalog.create_folder 
        @folder_name = @new_folder_name,
        @folder_id = @new_folder_id OUTPUT;
END
ELSE
BEGIN
    SET @new_folder_id = ( SELECT folder_id FROM catalog.folders WHERE name = @new_folder_name );
END;' + char(13) + char(10)  + char(13) + char(10);

PRINT @sql_cmd;


--  environment
SET @sql_cmd = N'
-- create environment if it doesn''t exist
IF NOT EXISTS ( SELECT 1 FROM catalog.environments WHERE folder_id = @new_folder_id AND name = @new_environment_name )
BEGIN
    EXEC catalog.create_environment 
        @environment_name = @new_environment_name,
        @folder_name = @new_folder_name;
END;' + char(13) + char(10);

SET @sql_cmd = @sql_cmd + N'
SET @new_environment_id = ( SELECT environment_id FROM catalog.environments WHERE folder_id = @new_folder_id AND name = @new_environment_name );' + char(13) + char(10) + char(13) + char(10) + char(13) + char(10);

PRINT @sql_cmd;
 

-- store the environment variable data in a cursor
SET @variable_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT      v.name,
                v.type,
                v.description,
                v.value,
                v.sensitive
    FROM        catalog.folders                 AS f
    JOIN        catalog.environments            AS e    ON  e.folder_id = f.folder_id
    JOIN        catalog.environment_variables   AS v    ON  v.environment_id = e.environment_id
    WHERE       f.name = @folder_name
    AND         e.name = @environment_name
    ORDER BY    v.name;


-- loop through the cursor to build the environment variable create statement
OPEN @variable_list;
FETCH NEXT FROM @variable_list INTO @name, @type, @description, @value, @sensitive;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd = N'-- create ' + @name + char(13) + char(10);

    SET @sql_cmd = @sql_cmd + N'SET @new_value = ' 
        +   ( 
            SELECT  CASE
                        WHEN @sensitive = 1
                            THEN '''<Placeholder>'''
                        WHEN @type <> N'String'
                            THEN '' + isnull(cast(@value AS nvarchar(4000)), '<Placeholder>') + ''
                        ELSE 'N' + '''' + isnull(cast(@value AS nvarchar(4000)), '<Placeholder>') + ''''
                    END
            ) + ';' + char(13) + char(10) + char(13) + char(10);

    PRINT @sql_cmd;

    PRINT N'IF NOT EXISTS ( SELECT 1 FROM catalog.environment_variables WHERE environment_id = @new_environment_id AND name = ''' + @name + ''')' + char(13) + char(10);
    PRINT N'BEGIN' + char(13) + char(10);
    PRINT N'    EXEC [catalog].create_environment_variable' + char(13) + char(10);
    PRINT N'        @variable_name = N''' + @name + ''',' + char(13) + char(10);
    PRINT N'        @data_type = N''' + @type + ''',' + char(13) + char(10);
    PRINT N'        @description = N''' + @description + ''',' + char(13) + char(10);
    PRINT N'        @value = @new_value,' + char(13) + char(10);
    PRINT N'        @sensitive = ' + convert(varchar(2), @sensitive) + ',' + char(13) + char(10);
    PRINT N'        @folder_name = @new_folder_name,' + char(13) + char(10);
    PRINT N'        @environment_name = @new_environment_name;' + char(13) + char(10);
    PRINT N'END' + char(13) + char(10) + char(13) + char(10);
 
    FETCH NEXT FROM @variable_list INTO @name, @type, @description, @value, @sensitive;
END;
