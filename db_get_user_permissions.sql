/* ================================================================================================
Purpose:
    Returns users in the current database and their associated permissions.
 
History:
    2020-10-14  Tom Hogan           Created.
================================================================================================ */

/* orphaned users */
SELECT      'z-Orphaned' AS login_name,
            dp.name      AS user_name,
            dp.type_desc AS user_type,
            ''           AS role_name,
            ''           AS permission_class,
            ''           AS permission_state,
            ''           AS permission_name,
            ''           AS permission_object
FROM        sys.database_principals AS dp
LEFT JOIN   sys.server_principals   AS sp   ON  sp.sid = dp.sid
            /* exclude default SQL users and SQL logins */
WHERE       dp.principal_id > 4
AND         dp.type = 'S'
AND         sp.name IS NULL
UNION ALL
/* database roles with no associated users */
SELECT      ''                             AS login_name,
            dp.name                        AS user_name,
            dp.type_desc                   AS user_type,
            ''                             AS role_name,
            isnull(pe.class_desc, '')      AS permission_class,
            isnull(pe.state_desc, '')      AS permission_state,
            isnull(pe.permission_name, '') AS permission_name,
            CASE
                WHEN pe.class = 1
                    THEN schema_name(o.schema_id) + '.' + o.name
                WHEN pe.class = 1
                AND  c.column_id IS NOT NULL
                    THEN schema_name(o.schema_id) + '.' + o.name + '(' + quotename(c.name) + ')'
                WHEN pe.class = 3
                    THEN s.name
                ELSE ''
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
AND         dp.type = 'R'
AND         rm.role_principal_id IS NULL
UNION ALL
/* permissions set via database roles */
SELECT      isnull(suser_sname(du.sid), '')    AS login_name,
            du.name                            AS user_name,
            du.type_desc                       AS user_type,
            ro.name                            AS role_name,
            isnull(pe.class_desc, '')          AS permission_class,
            isnull(pe.state_desc, '')          AS permission_state,
            isnull(pe.permission_name, '')     AS permission_name,
            CASE
                WHEN pe.class = 1
                    THEN schema_name(o.schema_id) + '.' + o.name
                WHEN pe.class = 1
                AND  c.column_id IS NOT NULL
                    THEN schema_name(o.schema_id) + '.' + o.name + '(' + quotename(c.name) + ')'
                WHEN pe.class = 3
                    THEN s.name
                ELSE ''
            END                                AS permission_object
FROM        sys.database_role_members   AS rm
JOIN        sys.database_principals     AS ro   ON  ro.principal_id = rm.role_principal_id
JOIN        sys.database_principals     AS du   ON  du.principal_id = rm.member_principal_id
LEFT JOIN   sys.database_permissions    AS pe   ON  pe.grantee_principal_id = ro.principal_id
LEFT JOIN   sys.objects                 AS o    ON  o.object_id = pe.major_id
LEFT JOIN   sys.schemas                 AS s    ON  s.schema_id = pe.major_id
LEFT JOIN   sys.columns                 AS c    ON  c.object_id = pe.major_id
                                                AND c.column_id = pe.minor_id
            /* exclude default SQL users and fixed database roles */
WHERE       du.principal_id > 4
AND         du.is_fixed_role = 0
UNION ALL
/* permissions set via the user directly */
SELECT      isnull(suser_sname(dp.sid), '')    AS login_name,
            dp.name                            AS user_name,
            dp.type_desc                       AS user_type,
            ''                                 AS role_name,
            isnull(pe.class_desc, '')          AS permission_class,
            isnull(pe.state_desc, '')          AS permission_state,
            isnull(pe.permission_name, '')     AS permission_name,
            CASE
                WHEN pe.class = 1
                    THEN schema_name(o.schema_id) + '.' + o.name
                WHEN pe.class = 1
                AND  c.column_id IS NOT NULL
                    THEN schema_name(o.schema_id) + '.' + o.name + '(' + quotename(c.name) + ')'
                WHEN pe.class = 3
                    THEN s.name
                ELSE ''
            END                                AS permission_object
FROM        sys.database_principals     AS dp
LEFT JOIN   sys.database_permissions    AS pe   ON  pe.grantee_principal_id = dp.principal_id
LEFT JOIN   sys.objects                 AS o    ON  o.object_id = pe.major_id
LEFT JOIN   sys.schemas                 AS s    ON  s.schema_id = pe.major_id
LEFT JOIN   sys.columns                 AS c    ON  c.object_id = pe.major_id
                                                AND c.column_id = pe.minor_id
            /* exclude default SQL users and fixed database roles */
WHERE       dp.principal_id > 4
AND         dp.is_fixed_role = 0
AND         dp.type <> 'R'
ORDER BY    login_name,
            user_name,
            role_name,
            permission_class,
            permission_name DESC,
            permission_object;
