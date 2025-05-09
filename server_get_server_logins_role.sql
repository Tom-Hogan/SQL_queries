/* ================================================================================================
Purpose:
    Lists logins and server roles.

Notes:
    Contains commented out predefined AND in the WHERE clause to filter results for a specific role.
 
History:
    2011-10-03  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      p.name        AS login_name,
            p.type_desc   AS login_type,
            p.is_disabled AS login_is_disabled,
            CASE
                WHEN r.name IS NULL
                    THEN ''
                ELSE r.name
            END           AS server_role,
            p.default_database_name,
            p.default_language_name,
            r.is_disabled AS role_is_disabled
FROM        sys.server_principals   AS p
JOIN        sys.server_role_members AS m    ON  m.member_principal_id = p.principal_id
JOIN        sys.server_principals   AS r    ON  r.principal_id = m.role_principal_id
WHERE       p.is_fixed_role <> 1
AND         p.name NOT LIKE '##%'
AND         p.name NOT LIKE 'NT SERVICE%'
AND         p.name NOT LIKE 'NT AUTHORITY%'
            /*
            === to get specific role ===
            */
--AND         r.name = 'sysadmin'
ORDER BY    p.name,
            r.name;
