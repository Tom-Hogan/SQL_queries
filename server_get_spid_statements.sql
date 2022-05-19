/* ================================================================================================
Purpose:
    Lists object names for current processes actively running on the current server.
 
History:
    2008-09-29  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      r.session_id,
            r.blocking_session_id,
            db_name(r.database_id)                 AS database_name,
            s.program_name,
            s.client_interface_name,
            s.login_name,
            object_name(h.objectid, r.database_id) AS spid_object,
            cast(h.text AS varchar(MAX))           AS spid_statement
FROM        sys.dm_exec_requests                AS r
JOIN        sys.dm_exec_sessions                AS s    ON  s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)  AS h
            /* active processes only */
WHERE       r.status <> 'sleeping'
AND         r.command NOT IN ('AWAITING COMMAND', 'LAZY WRITER', 'CHECKPOINT SLEEP');
