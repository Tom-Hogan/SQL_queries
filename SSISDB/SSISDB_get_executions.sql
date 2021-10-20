/* ================================================================================================
Purpose:
    Lists all package executions run on current server.

    *** Uncomment and update WHERE clause to filter results as needed.

History:
    2015-02-27  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


-- return results
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
SELECT      execution_id,
            folder_name,
            project_name,
            package_name,
            execution_status,
            start_time,
            end_time,
            duration_in_sec,
            server_name,
            executed_as_name,
            used_32_bit_runtime
FROM        cte_executions
            -- ------------------------------------------------------------------------------------------------
            -- put in whatever WHERE predicates you might like
            -- ------------------------------------------------------------------------------------------------
-- WHERE       folder_name = 'Data_warehouse'
-- WHERE       project_name = 'ETL_Validation'
-- WHERE       package_name = 'ETL_Validation_step_1'
-- WHERE       execution_status IN ('failed', 'ended unexpectedly')
ORDER BY    start_time DESC;
