/* ================================================================================================
Purpose:
    Lists CPU and memory data.

History:
    2017-09-20  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      i.cpu_count                                                         AS logical_cpu_count,
            i.hyperthread_ratio,
            i.cpu_count / i.hyperthread_ratio                                   AS physical_cpu_count,
            cast(round(( i.physical_memory_kb / 1024.0 ), 0) AS decimal(11, 0)) AS physical_memory_mb,
            m.sql_memory                                                        AS sql_server_max_memory_mb,
            i.sqlserver_start_time,
            i.affinity_type_desc
FROM        sys.dm_os_sys_info  AS i
CROSS APPLY (
            SELECT  value AS sql_memory
            FROM    sys.configurations
            WHERE   name = 'max server memory (MB)'
            )                   AS m
;
