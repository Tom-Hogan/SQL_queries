/* ================================================================================================
Purpose:
    Lists all package executions run on current server.

Notes:
    Contains some commented out predefined WHERE clauses.

History:
    2015-02-27  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


WITH
cte_executions AS 
(
    SELECT  execution_id,
            folder_name,
            project_name,
            replace(package_name, '.dtsx', '') AS package_name,
            CASE
                WHEN status = 1
                    THEN 'created'
                WHEN status = 2
                    THEN 'running'
                WHEN status = 3
                    THEN 'canceled'
                WHEN status = 4
                    THEN 'failed'
                WHEN status = 5
                    THEN 'pending'
                WHEN status = 6
                    THEN 'ended unexpectedly'
                WHEN status = 7
                    THEN 'succeeded'
                WHEN status = 8
                    THEN 'stopping'
                WHEN status = 9
                    THEN 'completed'
                ELSE ''
            END                                AS execution_status,
            start_time,
            end_time,
            datediff(ss, start_time, end_time) AS duration_in_sec,
            server_name,
            executed_as_name,
            use32bitruntime                    AS used_32_bit_runtime
    FROM    catalog.executions
)
SELECT      e.execution_id,
            e.folder_name,
            e.project_name,
            e.package_name,
            e.execution_status,
            e.start_time,
            e.end_time,
            e.duration_in_sec,
            e.server_name,
            e.executed_as_name,
            e.used_32_bit_runtime
FROM        cte_executions AS e
            /* 
            === add / modify as needed ====
            */
--WHERE       e.folder_name = 'Data_warehouse'
--WHERE       e.project_name = 'ETL_Validation'
--WHERE       e.package_name = 'ETL_Validation_step_1'
--WHERE       e.execution_status IN ('failed', 'ended unexpectedly')
ORDER BY    e.start_time DESC;
