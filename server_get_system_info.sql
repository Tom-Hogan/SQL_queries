/* ================================================================================================
Purpose:
    Lists CPU and memory data.

History:
    2017-09-20  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT  i.cpu_count                                                                  AS logical_cpu_count,
        i.hyperthread_ratio,
        i.cpu_count / i.hyperthread_ratio                                            AS physical_cpu_count,
        i.socket_count,
        i.cores_per_socket,
        i.softnuma_configuration_desc                                                AS softnuma_configuration,
        i.numa_node_count,
        cast(round(( i.physical_memory_kb / 1024.0 / 1024.0 ), 1) AS decimal(15, 1)) AS physical_memory_gb,
        cast(round(m.sql_memory / 1024.0, 1) AS decimal(15, 1))                      AS sql_server_max_memory_gb,
        i.sqlserver_start_time,
        i.affinity_type_desc
FROM    sys.dm_os_sys_info  AS i
CROSS APPLY
        (
            SELECT  cast(value AS int) AS sql_memory
            FROM    sys.configurations
            WHERE   name = 'max server memory (MB)'
        )                   AS m;
