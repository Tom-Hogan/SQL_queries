/* ================================================================================================
Purpose:
    Lists average and max times for connections on the current server.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific application.
 
History:
    2007-12-06  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      s.host_name,
            s.login_name,
            s.program_name,
            count(*)                                                                                           AS total_connections,
            cast(round(avg(datediff(ss, s.last_request_start_time, getdate())) / 1000.0, 2) AS decimal(11, 2)) AS average_idle_time_in_sec,
            cast(round(max(datediff(ss, s.last_request_start_time, getdate())) / 1000.0, 2) AS decimal(11, 2)) AS max_idle_time_in_sec
FROM        sys.dm_exec_sessions    AS s
            /*
            === to get specific application ===
            */
--WHERE       s.program_name = '.Net SqlClient Data Provider'
GROUP BY    s.host_name,
            s.login_name,
            s.program_name
ORDER BY    s.host_name,
            s.login_name,
            s.program_name;
