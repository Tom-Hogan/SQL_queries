/* ================================================================================================
Purpose:
    Outputs statements to recreate permissions for a given set of users in a database.

    *** Uncomment and update WHERE clause to filter for a specific user.
 
History:
    2016-01-20  Tom Hogan           Created, based on a script from: 
                                    http://www.sqlservercentral.com/scripts/Security/71562/.
================================================================================================ */

WITH cte_user_details ( sql_output, db_principal_name, sql_sort )
AS
    (
    -- ------------------------------------------------------------------------------------------------
    -- database user
    -- ------------------------------------------------------------------------------------------------
    SELECT  CASE
                WHEN dp.authentication_type IN (2, 0)   -- contained database user with password, user without login
                    THEN 'CREATE USER ' + ' ' + quotename(dp.name)
                            + ' WITHOUT LOGIN WITH DEFAULT_SCHEMA = ' + quotename(dp.default_schema_name) 
                            + ' , SID = '+ convert(varchar(1000), dp.sid) + ';'
                ELSE 'CREATE USER ' + quotename(dp.name) + ' FOR LOGIN ' + quotename(suser_sname(dp.sid)) 
                        + ' WITH DEFAULT_SCHEMA = ' + quotename(isnull(dp.default_schema_name, 'dbo')) + ';'
            END     AS sql_output,
            dp.name AS db_principal_name,
            1.0     AS sql_sort
    FROM    sys.database_principals AS dp
    JOIN    sys.server_principals   AS sp   ON  sp.name = dp.name
                                            AND sp.sid = dp.sid
            -- windows users, sql users, windows groups
            -- exclude default SQL users
    WHERE   dp.type IN ('U', 'S', 'G')
    AND     dp.principal_id > 4
    -- orphaned users
    UNION
    SELECT      'ALTER USER [' + dp.name + '] WITH LOGIN = [' + dp.name + ']' AS sql_output,
                dp.name                                                       AS db_principal_name,
                1.1                                                           AS sql_sort
    FROM        sys.database_principals AS dp
    LEFT JOIN   sys.server_principals   AS sp   ON  sp.name = dp.name
                                                AND sp.sid = dp.sid
                -- windows users, sql users, windows groups
                -- exclude default SQL users
    WHERE       dp.type IN ('U', 'S', 'G')
    AND         dp.principal_id > 4
    AND         sp.name IS NULL
    -- ------------------------------------------------------------------------------------------------
    -- custom database role
    -- ------------------------------------------------------------------------------------------------
    UNION
    SELECT      'CREATE ROLE ' + quotename(dp.name) + ' AUTHORIZATION ' + quotename(op.name) AS sql_output,
                dp.name                                                                      AS db_principal_name,
                1.5                                                                          AS sql_sort
    FROM        sys.database_principals AS dp
    LEFT JOIN   sys.database_principals AS op   ON  op.principal_id = dp.owning_principal_id
    WHERE       dp.type = 'R'
    AND         dp.principal_id > 0
    AND         dp.is_fixed_role = 0
    -- ------------------------------------------------------------------------------------------------
    -- database role permissions
    -- ------------------------------------------------------------------------------------------------
    UNION
    SELECT  'ALTER ROLE ' + quotename(dp.name) + ' ADD MEMBER ' + quotename(du.name) AS sql_output,
            du.name                                                                  AS db_principal_name,
            2.0                                                                      AS sql_sort
    FROM    sys.database_principals     AS dp
    JOIN    sys.database_role_members   AS dr   ON  dr.role_principal_id = dp.principal_id
    JOIN    sys.database_principals     AS du   ON  du.principal_id = dr.member_principal_id
            -- exclude default SQL users
    WHERE   du.principal_id > 4
    -- ------------------------------------------------------------------------------------------------
    -- database level permissions
    -- ------------------------------------------------------------------------------------------------
    UNION
    SELECT  CASE
                WHEN p.state <> 'W' -- W = Grant with grant option
                    THEN p.state_desc
                ELSE 'GRANT'
            END + ' ' + p.permission_name + ' TO ' + '[' + user_name(pr.principal_id) + ']' COLLATE DATABASE_DEFAULT    --TO <user name>
                +   CASE
                        WHEN p.state <> 'W'
                            THEN ''
                        ELSE ' WITH GRANT OPTION'
                    END AS sql_output,
            pr.name     AS db_principal_name,
            3.0         AS sql_sort
    FROM    sys.database_permissions    AS p
    JOIN    sys.database_principals     AS pr   ON  pr.principal_id = p.grantee_principal_id
            -- windows users, sql users, windows groups
            -- exclude default SQL users
    WHERE   pr.type IN ('U', 'S', 'G')
    AND     pr.principal_id > 4
    AND     p.major_id = 0
    -- ------------------------------------------------------------------------------------------------
    -- schema permissions
    -- ------------------------------------------------------------------------------------------------
    UNION
    SELECT  CASE
                WHEN p.state <> 'W' -- W = Grant with grant option
                    THEN p.state_desc
                ELSE 'GRANT'
            END + ' ' + p.permission_name + ' ON ' + p.class_desc + '::' COLLATE DATABASE_DEFAULT + quotename(s.name) 
                + ' TO '+ quotename(user_name(p.grantee_principal_id))COLLATE DATABASE_DEFAULT 
                +   CASE
                        WHEN p.state <> 'W'
                            THEN ''
                        ELSE ' WITH GRANT OPTION'
                END     AS sql_output,
            pr.name     AS db_principal_name,
            4.0         AS sql_sort
    FROM    sys.database_permissions    AS p
    JOIN    sys.schemas                 AS s    ON  s.schema_id = p.major_id
    JOIN    sys.database_principals     AS pr   ON  pr.principal_id = p.grantee_principal_id
    WHERE   p.class = 3 -- schema
    -- ------------------------------------------------------------------------------------------------
    -- object specific permissions
    -- ------------------------------------------------------------------------------------------------
    UNION
    SELECT      CASE
                    WHEN p.state <> 'W' -- W = Grant with grant option
                        THEN p.state_desc
                    ELSE 'GRANT'
                END + ' ' + p.permission_name + ' ON ' + quotename(s.name) + '.' + quotename(o.name) 
                    +   CASE
                            WHEN c.column_id IS NULL
                                THEN space(0)
                            ELSE '(' + quotename(c.name) + ')'
                        END + ' TO ' + quotename(pr.name)COLLATE DATABASE_DEFAULT
                    +   CASE
                            WHEN p.state <> 'W'
                                THEN ''
                            ELSE ' WITH GRANT OPTION'
                        END     AS sql_output,
                pr.name         AS db_principal_name,
                5.0             AS sql_sort
    FROM        sys.database_permissions    AS p
    JOIN        sys.objects                 AS o    ON  o.object_id = p.major_id
    JOIN        sys.schemas                 AS s    ON  s.schema_id = o.schema_id
    JOIN        sys.database_principals     AS pr   ON  pr.principal_id = p.grantee_principal_id
    LEFT JOIN   sys.columns                 AS c    ON  c.column_id = p.minor_id
                                                    AND c.object_id = p.major_id
    )
SELECT      sql_output,
            db_principal_name,
            sql_sort
FROM        cte_user_details
            -- ------------------------------------------------------------------------------------------------
            -- update as desired
            -- ------------------------------------------------------------------------------------------------
--WHERE       db_principal_name = 'name'
ORDER BY    sql_sort,
            db_principal_name
;
