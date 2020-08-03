CREATE OR ALTER PROCEDURE dbo.create_stage_tables
    @dw_name          nvarchar(128),
    @dim_schema_name  nvarchar(128),
    @dim_table_name   nvarchar(128),
    @stage_table_type varchar(20) = 'ALL'
AS
/* ================================================================================================
Purpose:
    Creates staging tables for a specific dimension.  Staging tables are used in the SCD template 
    to handle new, SCD 1 changes, SCD 2 changes and inferred records.

Example:
    EXEC dbo.create_stage_tables
        @dw_name = 'data_warehouse',   
        @dim_schema_name = 'dbo',
        @dim_table_name = 'dim_sales_rep',
        @stage_table_type = 'all'

History:
    Based on a script created by Craig Love of Pragmatic Works.
================================================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;


DECLARE @sql_statement    nvarchar(MAX),
        @table_sql        nvarchar(MAX),
        @pk_field_name    nvarchar(128),
        @schema_name      nvarchar(128),
        @table_name       nvarchar(128),
        @column_name      nvarchar(128),
        @data_type        nvarchar(128),
        @column_delimiter varchar(3),
        @error_msg        nvarchar(500);

-- create temp table to hold table structure
CREATE TABLE #table_schema (
    row_id      int           NOT NULL IDENTITY(1, 1),
    schema_name nvarchar(128) NOT NULL,
    table_name  nvarchar(128) NOT NULL,
    column_name nvarchar(128) NOT NULL,
    data_type   varchar(100)  NOT NULL,
    pk_flag     char(1)       NOT NULL
);

SET @stage_table_type = lower(@stage_table_type);


-- run process to create tables
BEGIN TRY
    BEGIN TRAN;

    -- ------------------------------------------------------------------------------------------------
    -- paramater checks
    -- ------------------------------------------------------------------------------------------------
    -- check @stage_table_type paramater
    IF @stage_table_type NOT IN ('all', 'new', 'scd1', 'scd2')
    BEGIN
        SET @error_msg = N'Parameter @stage_table_type accepts only the following parameters: ''all'', ''new'', ''scd1'', ''scd2''';
        RAISERROR(@error_msg, 15, 1);
    END;


    -- ------------------------------------------------------------------------------------------------
    -- get table definition for given dimension
    -- ------------------------------------------------------------------------------------------------
    SET @sql_statement = cast('' AS nvarchar(MAX)) + N'
INSERT INTO #table_schema (
            schema_name,
            table_name,
            column_name,
            data_type,
            pk_flag
            )
SELECT      quotename(s.name)                       AS schema_name,
            quotename(cast(o.name AS varchar(128))) AS table_name,
            quotename(cast(c.name AS varchar(128))) AS column_name,
            cast(t.name AS varchar(30)) 
                +   CASE
                        WHEN t.name = ''varchar'' 
                            THEN ''('' +    CASE
                                                WHEN c.max_length = -1 THEN ''max''
                                                ELSE cast(c.max_length AS varchar(4))
                                            END + '')''
                        WHEN t.name = ''char'' 
                            THEN ''('' +    CASE
                                                WHEN c.max_length = -1 THEN ''max''
                                                ELSE cast(c.max_length AS varchar(4))
                                            END + '')''
                        WHEN t.name = ''nvarchar'' 
                            THEN ''('' +    CASE
                                                WHEN c.max_length = -1 THEN ''max''
                                                ELSE cast((c.max_length / 2) AS varchar(4))
                                            END + '')''
                        WHEN t.name = ''nchar'' 
                            THEN ''('' +    CASE
                                                WHEN c.max_length = -1 THEN ''max''
                                                ELSE cast((c.max_length / 2) AS varchar(4))
                                            END + '')''
                        ELSE ''''
                    END                             AS data_tyoe,
            CASE
                WHEN i.name IS NOT NULL
                    THEN ''Y''
                ELSE ''N''
            END                                     AS pk_flag
FROM        ' + @dw_name + N'.sys.columns            AS c
JOIN        ' + @dw_name + N'.sys.objects            AS o    ON  o.object_id = c.object_id 
JOIN        ' + @dw_name + N'.sys.types              AS t    ON  t.user_type_id = c.user_type_id
JOIN        ' + @dw_name + N'.sys.schemas            AS s    ON  s.schema_id = o.schema_id
LEFT JOIN   ' + @dw_name + N'.sys.index_columns      AS ic   ON  ic.object_id = c.object_id
                                                                AND ic.column_id = c.column_id 
LEFT JOIN   ' + @dw_name + N'.sys.indexes            AS i    ON  i.object_id = o.object_id
                                                                AND i.index_id = ic.index_id
                                                                AND i.is_primary_key = 1
WHERE       o.type = ''U''
AND         s.name = ''' + @dim_schema_name + N'''
AND         o.name = ''' + @dim_table_name + N'''';


    -- load temp table
    EXEC sys.sp_executesql 
        @stmt = @sql_statement;


    -- ------------------------------------------------------------------------------------------------
    -- table schema checks
    -- ------------------------------------------------------------------------------------------------
    -- check table existence
    IF NOT EXISTS ( SELECT 1 FROM #table_schema ) 
    BEGIN
        SET @error_msg = N'The dimension table ' + lower(@dim_schema_name) + N'.' + lower(@dim_table_name) + N' does not exist.  Process aborted.';
        RAISERROR(@error_msg, 15, 1);

        RETURN 0;
    END;

    -- get name of PK Field.  If none found, raise error
    SET @pk_field_name = (
                         SELECT column_name
                         FROM   #table_schema
                         WHERE  pk_flag = 'Y'
                         );

    -- test @pk_field_name
    IF @pk_field_name IS NULL
    BEGIN
        SET @error_msg = N'Target Table does not have a Primary Key.  Process aborting.';
        RAISERROR(@error_msg, 15, 1);
    END;

 
    -- ------------------------------------------------------------------------------------------------
    -- load cursor with field names
    -- ------------------------------------------------------------------------------------------------
    DECLARE table_schema_curs CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
    FOR
        SELECT      schema_name,
                    table_name,
                    column_name,
                    data_type
        FROM        #table_schema
        ORDER BY    row_id;


    -- ------------------------------------------------------------------------------------------------
    -- reset SQL statement variable
    -- ------------------------------------------------------------------------------------------------
    SET @sql_statement = '';


    -- ------------------------------------------------------------------------------------------------
    -- stage_dimension_new
    -- ------------------------------------------------------------------------------------------------
    IF @stage_table_type IN ('all', 'new')
    BEGIN
        -- initialize variables for table creation statement
        SET @table_sql = cast('' AS nvarchar(MAX)) + N'CREATE TABLE [' + @dim_schema_name + N'].[stage_' + lower(@dim_table_name) + N'_new] (';
        SET @column_delimiter = '';

        -- open the cursor and loop through the fields
        OPEN table_schema_curs;
        FETCH NEXT FROM table_schema_curs INTO @schema_name, @table_name, @column_name, @data_type;

        -- build the table creation statement for each column
        --   except Primary Key
        WHILE @@fetch_status = 0
        BEGIN
            IF @column_name <> @pk_field_name
            BEGIN
                SET @table_sql = @table_sql + @column_delimiter + @column_name + ' ' + @data_type + N' NOT NULL';
                SET @column_delimiter = ',';
            END;

            FETCH NEXT FROM table_schema_curs INTO @schema_name, @table_name, @column_name, @data_type;
        END;

        -- complete table creation statement
        SET @table_sql = @table_sql + N'); ';


        -- close cursor
        CLOSE table_schema_curs;


        -- build SQL query to create table(s)
        SET @sql_statement = @sql_statement + @table_sql;
    END;


    -- ------------------------------------------------------------------------------------------------
    -- stage_dimension_scd1
    -- ------------------------------------------------------------------------------------------------
    IF @stage_table_type IN ('all', 'scd1')
    BEGIN
        -- initialize variables for table creation statement
        SET @table_sql = cast('' AS nvarchar(MAX)) + N'CREATE TABLE [' + @dim_schema_name + N'].[stage_' + lower(@dim_table_name) + N'_scd1] (';
        SET @column_delimiter = '';

        -- open the cursor and loop through the fields
        OPEN table_schema_curs;
        FETCH NEXT FROM table_schema_curs INTO @schema_name, @table_name, @column_name, @data_type;

        -- build the table creation statement for each column
        --   except row history fields
        WHILE @@fetch_status = 0
        BEGIN
            IF (   @column_name <> '[row_current_flag]'
               AND @column_name <> '[row_start_datetime]'
               AND @column_name <> '[row_end_datetime]'
               )
            BEGIN
                SET @table_sql = @table_sql + @column_delimiter + @column_name + ' ' + @data_type + N' NOT NULL';
                SET @column_delimiter = ',';
            END;

            FETCH NEXT FROM table_schema_curs INTO @schema_name, @table_name, @column_name, @data_type;
        END;

        -- complete table creation statement
        SET @table_sql = @table_sql + N'); ';


        -- close cursor
        CLOSE table_schema_curs;


        -- build SQL query to create table(s)
        SET @sql_statement = @sql_statement + @table_sql;
    END;


    -- ------------------------------------------------------------------------------------------------
    -- stage_dimension_scd2
    -- ------------------------------------------------------------------------------------------------
    IF @stage_table_type IN ('all', 'scd2')
    BEGIN
        -- initialize variables for table creation statement
        SET @table_sql = cast('' AS nvarchar(MAX)) + N'CREATE TABLE [' + @dim_schema_name + N'].[stage_' + lower(@dim_table_name) + N'_scd2] (';
        SET @column_delimiter = '';

        -- open the cursor and loop through the fields
        OPEN table_schema_curs;
        FETCH NEXT FROM table_schema_curs
        INTO @schema_name,
                @table_name,
                @column_name,
                @data_type;

        -- build the table creation statement for each column
        WHILE @@fetch_status = 0
        BEGIN
            SET @table_sql = @table_sql + @column_delimiter + @column_name + ' ' + @data_type + N' NOT NULL';
            SET @column_delimiter = ',';

            FETCH NEXT FROM table_schema_curs INTO @schema_name, @table_name, @column_name, @data_type;
        END;

        -- complete table creation statement
        SET @table_sql = @table_sql + N'); ';


        -- close cursor
        CLOSE table_schema_curs;


        -- build SQL query to create table(s)
        SET @sql_statement = @sql_statement + @table_sql;
    END;


    -- ------------------------------------------------------------------------------------------------
    -- create the tables
    -- ------------------------------------------------------------------------------------------------
    EXEC sys.sp_executesql
        @stmt = @sql_statement;


    -- deallocate the cursor
    DEALLOCATE table_schema_curs;


    COMMIT TRAN;
END TRY
BEGIN CATCH
    DECLARE @ErrorMessage  nvarchar(4000),
            @ErrorSeverity int,
            @ErrorState    int;

    SELECT  @ErrorMessage  = error_message(),
            @ErrorSeverity = error_severity(),
            @ErrorState    = error_state();

    -- Use RAISERROR inside the CATCH block to return error
    --  information about the original error that caused
    --  execution to jump to the CATCH block.
    RAISERROR( @ErrorMessage,     -- message text
               @ErrorSeverity,    -- severity
               @ErrorState        -- state
               );


    -- deallocate the cursor
    DEALLOCATE table_schema_curs;

    ROLLBACK TRAN;
END CATCH;

GO
