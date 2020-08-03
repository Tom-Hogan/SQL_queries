/* ================================================================================================
Purpose:
    Lists all parameters associated with a given execution ID.

History:
    2018-12-18  Tom Hogan           Created.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


DECLARE @execution_id int;

SET @execution_id = 0;


-- return results
SELECT      execution_parameter_id,
            CASE
                WHEN object_type = 20
                    THEN 'Project'
                WHEN object_type = 30
                    THEN 'Package'
                WHEN object_type = 50
                    THEN 'System'
                ELSE ''
            END                   AS paramneter_type,
            parameter_data_type,
            parameter_name,
            parameter_value,
            sensitive,
            required,
            value_set,
            runtime_override,
            CASE
                WHEN object_type = 50
                    THEN 1
                WHEN object_type = 20
                    THEN 2
                WHEN object_type = 30
                    THEN 3
                ELSE 0
            END                   AS sort_order
FROM        catalog.execution_parameter_values
WHERE       execution_id = @execution_id
ORDER BY    sort_order,
            execution_parameter_id;
