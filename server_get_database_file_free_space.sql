/* ================================================================================================
Purpose:
    Lists current file sizes with free space per file for all databases.

History:
    2017-02-17  Tom Hogan           Created.
================================================================================================ */
USE master;
SET NOCOUNT ON;


DECLARE @database_name nvarchar(128),
        @database_list CURSOR,
        @sql_cmd       nvarchar(MAX),
        @debug         tinyint = 0;


/* create a temp table to hold results */
DROP TABLE IF EXISTS #db_file;

CREATE TABLE #db_file
(
    database_name     nvarchar(128)  NULL,
    file_type         nvarchar(60)   NULL,
    file_name         nvarchar(128)  NOT NULL,
    size_in_MB        decimal(15, 2) NULL,
    free_space_in_MB  decimal(15, 2) NULL,
    max_size          varchar(25)    NULL,
    current_growth    varchar(25)    NULL,
    is_read_only      bit            NOT NULL,
    is_sparse         bit            NOT NULL,
    is_percent_growth bit            NOT NULL,
    physical_name     nvarchar(260)  NOT NULL
);


/*
    use a cursor to store database names
     - worth through the cursor to create and execute a statement that inserts each database's file size information
    into the temp table
*/
SET @database_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      quotename(name)
    FROM        sys.databases
    WHERE       state = 0   /* online */
    ORDER BY    name;


OPEN @database_list;
FETCH NEXT FROM @database_list INTO @database_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SET @sql_cmd =
        N'
        USE ' + @database_name + N';

        INSERT INTO #db_file
        (
                database_name,
                file_type,
                file_name,
                size_in_MB,
                free_space_in_MB,
                max_size,
                current_growth,
                is_read_only,
                is_sparse,
                is_percent_growth,
                physical_name
        )
        SELECT  db_name()                                                                                           AS database_name,
                type_desc                                                                                           AS file_type,
                name                                                                                                AS file_name,
                cast(size / 128.0 AS decimal(15, 2))                                                                AS size_in_MB,
                cast(( size / 128.0 ) - cast(fileproperty(name, ''SpaceUsed'') AS int) / 128.0 AS decimal(15, 2))   AS free_space_in_MB,
                CASE
                    WHEN max_size = -1
                        THEN ''Unlimited''
                    ELSE cast(( max_size / 128 ) AS varchar(20)) + '' MB''
                END                                                                                                 AS max_size,
                CASE
                    WHEN is_percent_growth = 1
                        THEN cast(( growth ) AS varchar(20)) + ''%''
                    ELSE cast(( growth / 128 ) AS varchar(20)) + '' MB''
                END                                                                                                 AS current_growth,
                is_read_only,
                is_sparse,
                is_percent_growth,
                physical_name
        FROM    sys.database_files;';


    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @database_list INTO @database_name;
END;


/*
    return results
*/
IF @debug = 0
    SELECT      database_name,
                file_type,
                file_name,
                sum(size_in_MB) OVER ( PARTITION BY database_name
                                       ORDER BY database_name
                                     ) AS database_size_in_MB,
                size_in_MB,
                free_space_in_MB,
                max_size,
                current_growth,
                is_read_only,
                is_sparse,
                is_percent_growth,
                physical_name
    FROM        #db_file
    --WHERE       free_space_in_MB > 10000
    --AND         file_type = 'ROWS'
    ORDER BY    database_name,
                file_type DESC;
