/* ================================================================================================
Purpose:
    Example commands used to fix orpaned users after a restore.
 
History:
    2016-05-25  Tom Hogan           Created, based on MSDN article.
                                    https://msdn.microsoft.com/en-us/library/ms175475(v=sql.130).aspx
================================================================================================ */
RAISERROR(N'You want to run these statements one at a time.', 20, 1) WITH LOG;
GO

/*
    get orphaned users
*/
SELECT      dp.type_desc AS user_type,
            dp.sid,
            dp.name      AS user_name
FROM        sys.database_principals AS dp
LEFT JOIN   sys.server_principals   AS sp   ON  sp.sid = dp.sid
WHERE       sp.sid IS NULL
AND         dp.authentication_type_desc = 'INSTANCE'
ORDER BY    dp.name;

/*
-- users with no associated login
SELECT      dp.principal_id,
            dp.name        AS database_user,
            dp.type_desc   AS user_type,
            sp.name        AS login_name,
            sp.type_desc   AS login_type,
            sp.is_disabled AS is_login_disabled
FROM        sys.database_principals AS dp
LEFT JOIN   sys.server_principals   AS sp   ON  sp.sid = dp.sid
WHERE       dp.type IN ('S', 'U') /* SQL User, Windows User */
AND         dp.principal_id > 4
AND         sp.sid IS NULL
ORDER BY    dp.name;
-- */

/*
    if it doesn't exist, create login for orphaned user
    === use SID returned in above query ===
*/
CREATE LOGIN [<login_name>]
    WITH PASSWORD = '<enterStrongPasswordHere>',
         SID = <sidFromAbove>;


/*
    map user to login
*/
ALTER USER [<user_name>]
    WITH LOGIN = [<login_name>];


/*
    change password (if needed)
*/
ALTER LOGIN [<login_name>] WITH PASSWORD = '<enterStrongPasswordHere>';
