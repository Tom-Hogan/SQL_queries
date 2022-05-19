/* ================================================================================================
Purpose:
    Lists database logins and roles for all databases.
 
History:
    2004-11-29  Tom Hogan           Created.
    2008-05-08  Tom Hogan           Updated to use 2005 sys views.
================================================================================================ */
USE master;
SET NOCOUNT ON;


DECLARE @sql_cmd       nvarchar(4000),
        @database_list CURSOR,
        @database_name nvarchar(128),
        @debug         tinyint = 0;
        

/* create a temp table to hold results */
DROP TABLE IF EXISTS #results;

CREATE TABLE #results
(
    database_name         nvarchar(128) NOT NULL,
    user_name             nvarchar(128) NULL,
    database_role         nvarchar(128) NULL,
    login_name            nvarchar(128) NULL,
    default_database_name nvarchar(128) NULL,
    default_schema_name   nvarchar(128) NULL,
    login_type_desc       nvarchar(60)  NULL
);


/*
    use a cursor to store database names
     - worth through the cursor to create and execute a statement that inserts each database's logins and their associated
    roles into the temp table
*/
SET @database_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      name
    FROM        sys.databases
    WHERE       name NOT IN ('master', 'model', 'tempdb')
    AND         state = 0
    ORDER BY    name;


OPEN @database_list;
FETCH NEXT FROM @database_list INTO @database_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SELECT  @sql_cmd =
        N'
        INSERT INTO #results
        (
                    database_name,
                    user_name,
                    database_role,
                    login_name,
                    default_database_name,
                    default_schema_name,
                    login_type_desc
        )
        SELECT      N' + quotename(@database_name, '''') + N'AS database_name,
                    p.name                           AS user_name,
                    coalesce(rm.role_name, ''public'') AS database_role,
                    l.name                           AS login_name,
                    l.default_database_name,
                    p.default_schema_name,
                    p.type_desc                      AS login_type_desc
        FROM        ' + quotename(@database_name) + N'.sys.database_principals    AS p
        LEFT JOIN   (
                        SELECT      m.member_principal_id,
                                    CASE
                                        WHEN ( r.principal_id IS NULL )
                                            THEN ''public''
                                        ELSE r.name
                                    END AS role_name
                        FROM        ' + quotename(@database_name) + N'.sys.database_role_members  AS m
                        LEFT JOIN   ' + quotename(@database_name) + N'.sys.database_principals    AS r    ON  r.principal_id = m.role_principal_id
                    )                                             AS rm   ON  rm.member_principal_id = p.principal_id
        LEFT JOIN   ' + quotename(@database_name) + N'.sys.server_principals      AS l    ON  l.sid = p.sid
        WHERE       p.principal_id > 4  /* 1 = dbo, 2 = guest, 3 = information_schema, 4 = sys */
        AND         p.type <> ''R'';';


    IF @debug = 1
        PRINT @sql_cmd;

    IF @debug = 0
        EXEC sys.sp_executesql
            @stmt = @sql_cmd;

    FETCH NEXT FROM @database_list INTO @database_name;
END;


/* get logins not associated with a database (beside master) into the temp table */
WITH
cte_logins ( login_name ) AS
(
    SELECT  'sa'
    UNION ALL
    SELECT  'BUILTIN\Administrators'
    UNION ALL
    SELECT  'NT AUTHORITY\SYSTEM'
    UNION ALL
    SELECT  login_name FROM #results
)
INSERT INTO #results
(
    database_name,
    login_name
)
SELECT  'zz Not associated',
        p.name
FROM    master.sys.server_principals    AS p
WHERE   p.type <> 'R'
AND     NOT EXISTS
        (
            SELECT  1
            FROM    cte_logins AS l
            WHERE   p.name = l.login_name
        );


/*
    return results
*/
IF @debug = 0
    SELECT      database_name,
                user_name,
                database_role,
                login_name,
                default_database_name,
                default_schema_name,
                login_type_desc
    FROM        #results
    WHERE       login_name NOT LIKE '##MS%'
    AND         login_name NOT LIKE 'NT SERVICE%'
    ORDER BY    database_name,
                user_name,
                database_role,
                login_name;
