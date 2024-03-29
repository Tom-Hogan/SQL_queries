/* ================================================================================================
Purpose:
    Gets all database level permissions on the current server.

History:
    2018-12-11  Tom Hogan           Created.
================================================================================================ */
USE master;
SET NOCOUNT ON;


DECLARE @sql_cmd       nvarchar(MAX),
        @database_list CURSOR,
        @database_name nvarchar(128),
        @debug         tinyint = 0;


/* create a temp table to hold results */
DROP TABLE IF EXISTS #results;

CREATE TABLE #results
(
    database_name     nvarchar(128) NOT NULL,
    login_name        nvarchar(128) NULL,
    user_name         nvarchar(128) NULL,
    user_type         nvarchar(60)  NULL,
    role_name         nvarchar(128) NULL,
    permission_class  nvarchar(60)  NULL,
    permission_state  nvarchar(60)  NULL,
    permission_name   nvarchar(128) NULL,
    permission_object nvarchar(500) NULL
);


/*
    use a cursor to store database names
     - worth through the cursor to create and execture a statement that inserts each database's users and theor associated
    roles into the temp table
*/
SET @database_list = CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
    SELECT      name
    FROM        sys.databases
    WHERE       name NOT IN ('master', 'model', 'msdb', 'tempdb', 'ssisdb')
    AND         name NOT LIKE 'ReportServer%%'
    AND         state = 0
    ORDER BY    name;


OPEN @database_list;
FETCH NEXT FROM @database_list INTO @database_name;

WHILE ( @@fetch_status = 0 )
BEGIN
    SELECT  @sql_cmd =
        cast('' AS nvarchar(MAX)) + N'
    USE ' + quotename(@database_name) + N';

    INSERT INTO #results
    (
                database_name,
                login_name,
                user_name,
                user_type,
                role_name,
                permission_class,
                permission_state,
                permission_name,
                permission_object
    )
    /* database roles with no associated users */
    SELECT      ' + quotename(@database_name, '''') + N'  AS database_name,
                ''''                             AS login_name,
                dp.name                        AS user_name,
                dp.type_desc                   AS user_type,
                ''''                             AS role_name,
                isnull(pe.class_desc, '''')      AS permission_class,
                isnull(pe.state_desc, '''')      AS permission_state,
                isnull(pe.permission_name, '''') AS permission_name,
                CASE
                    WHEN pe.class = 1
                        THEN schema_name(o.schema_id) + ''.'' + o.name
                    WHEN pe.class = 1
                    AND  c.column_id IS NOT NULL
                        THEN schema_name(o.schema_id) + ''.'' + o.name + ''('' + quotename(c.name) + '')''
                    WHEN pe.class = 3
                        THEN s.name
                    ELSE ''''
                END                            AS permission_object
    FROM        sys.database_principals     AS dp
    LEFT JOIN   sys.database_role_members   AS rm   ON  rm.role_principal_id = dp.principal_id
    LEFT JOIN   sys.database_permissions    AS pe   ON  pe.grantee_principal_id = dp.principal_id
    LEFT JOIN   sys.objects                 AS o    ON  o.object_id = pe.major_id
    LEFT JOIN   sys.schemas                 AS s    ON  s.schema_id = pe.major_id
    LEFT JOIN   sys.columns                 AS c    ON  c.object_id = pe.major_id
                                                    AND c.column_id = pe.minor_id
                /* exclude default SQL users and fixed database roles */
    WHERE       dp.principal_id > 4
    AND         dp.is_fixed_role = 0
    AND         dp.type = ''R''
    AND         rm.role_principal_id IS NULL
    UNION ALL
    /* permissions set via database roles */
    SELECT      ' + quotename(@database_name, '''') + N'  AS database_name,
                CASE
                    WHEN sp.name IS NULL
                        THEN ''z-Orphaned''
                    ELSE isnull(suser_sname(dp.sid), '''')
                END                            AS login_name,
                dp.name                        AS user_name,
                dp.type_desc                   AS user_type,
                ro.name                        AS role_name,
                isnull(pe.class_desc, '''')      AS permission_class,
                isnull(pe.state_desc, '''')      AS permission_state,
                isnull(pe.permission_name, '''') AS permission_name,
                CASE
                    WHEN pe.class = 1
                        THEN schema_name(o.schema_id) + ''.'' + o.name
                    WHEN pe.class = 1
                    AND  c.column_id IS NOT NULL
                        THEN schema_name(o.schema_id) + ''.'' + o.name + ''('' + quotename(c.name) + '')''
                    WHEN pe.class = 3
                        THEN s.name
                    ELSE ''''
                END                            AS permission_object
    FROM        sys.database_role_members   AS rm
    JOIN        sys.database_principals     AS ro   ON  ro.principal_id = rm.role_principal_id
    JOIN        sys.database_principals     AS dp   ON  dp.principal_id = rm.member_principal_id
    LEFT JOIN   sys.server_principals       AS sp   ON  sp.sid = dp.sid
    LEFT JOIN   sys.database_permissions    AS pe   ON  pe.grantee_principal_id = ro.principal_id
    LEFT JOIN   sys.objects                 AS o    ON  o.object_id = pe.major_id
    LEFT JOIN   sys.schemas                 AS s    ON  s.schema_id = pe.major_id
    LEFT JOIN   sys.columns                 AS c    ON  c.object_id = pe.major_id
                                                    AND c.column_id = pe.minor_id
                /* exclude default SQL users and fixed database roles */
    WHERE       dp.principal_id > 4
    AND         dp.is_fixed_role = 0
    UNION ALL
    /* permissions set via the user directly */
    SELECT      ' + quotename(@database_name, '''') + N'  AS database_name,
                CASE
                    WHEN sp.name IS NULL
                        THEN ''z-Orphaned''
                    ELSE isnull(suser_sname(dp.sid), '''')
                END                            AS login_name,
                dp.name                        AS user_name,
                dp.type_desc                   AS user_type,
                ''''                             AS role_name,
                isnull(pe.class_desc, '''')      AS permission_class,
                isnull(pe.state_desc, '''')      AS permission_state,
                isnull(pe.permission_name, '''') AS permission_name,
                CASE
                    WHEN pe.class = 1
                        THEN schema_name(o.schema_id) + ''.'' + o.name
                    WHEN pe.class = 1
                    AND  c.column_id IS NOT NULL
                        THEN schema_name(o.schema_id) + ''.'' + o.name + ''('' + quotename(c.name) + '')''
                    WHEN pe.class = 3
                        THEN s.name
                    ELSE ''''
                END                            AS permission_object
    FROM        sys.database_principals     AS dp
    LEFT JOIN   sys.server_principals       AS sp   ON  sp.sid = dp.sid
    LEFT JOIN   sys.database_permissions    AS pe   ON  pe.grantee_principal_id = dp.principal_id
    LEFT JOIN   sys.objects                 AS o    ON  o.object_id = pe.major_id
    LEFT JOIN   sys.schemas                 AS s    ON  s.schema_id = pe.major_id
    LEFT JOIN   sys.columns                 AS c    ON  c.object_id = pe.major_id
                                                    AND c.column_id = pe.minor_id
                /* exclude default SQL users and fixed database roles */
    WHERE       dp.principal_id > 4
    AND         dp.is_fixed_role = 0
    AND         dp.type <> ''R''';


    IF @debug = 1
        SELECT  @sql_cmd AS [processing-instruction(x)]
        FOR XML PATH('');

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
                login_name,
                user_name,
                user_type,
                role_name,
                permission_class,
                permission_state,
                permission_name,
                permission_object
    FROM        #results
    WHERE       permission_name <> 'CONNECT'
    ORDER BY    database_name,
                login_name,
                user_name,
                role_name,
                permission_object,
                permission_state,
                permission_name;
