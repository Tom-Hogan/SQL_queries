/* ================================================================================================
Purpose:
    Returns check constraint information.

    *** Uncomment and update WHERE clause to filter for a specific table.
 
History:
    2016-10-19  Tom Hogan           Created, based on script by Phil Factor.
================================================================================================ */

WITH cte_details
AS
    (
    SELECT  object_schema_name(parent_object_id)  AS table_schema,
            object_name(parent_object_id)         AS table_name,
            name                                  AS constraint_name,
            CASE
                WHEN parent_column_id > 0   -- 0 means that it is a table constraint
                    THEN col_name(parent_object_id, parent_column_id)
                ELSE '(Table)'
            END                                   AS column_name,
            definition                            AS constraint_definition
    FROM    sys.check_constraints
    )
SELECT      *
FROM        cte_details
            -- ------------------------------------------------------------------------------------------------
            -- to get specific table
            -- ------------------------------------------------------------------------------------------------
--WHERE       table_name = ''
ORDER BY    table_schema,
            table_name,
            constraint_name
;
