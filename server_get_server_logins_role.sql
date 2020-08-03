/* ================================================================================================
Purpose:
    Lists logins and server roles.

    *** Uncomment and update WHERE clause to filter results for a specific role.
 
History:
    2011-10-03  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      p.name AS login_name,
            r.name AS server_role,
            p.type_desc,
            p.default_database_name,
            p.is_disabled
FROM        sys.server_principals   AS p
LEFT JOIN   sys.server_role_members AS m    ON  m.member_principal_id = p.principal_id
LEFT JOIN   sys.server_principals   AS r    ON  r.principal_id = m.role_principal_id
            -- ------------------------------------------------------------------------------------------------
            -- to get a specific role(s)
            -- ------------------------------------------------------------------------------------------------
WHERE       p.is_fixed_role <> 1
AND         p.name NOT LIKE '##%'
--AND         r.name = 'sysadmin'
ORDER BY    p.name,
            r.name
;
