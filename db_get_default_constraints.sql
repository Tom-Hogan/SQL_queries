/* ================================================================================================
Purpose:
    Returns default constraint information.

Notes:
    Contains commented out predefined WHERE clause to filter results for a specific table.
 
History:
    2016-10-19  Tom Hogan           Created, based on script by Phil Factor.
================================================================================================ */
WITH
cte_details AS
(
    SELECT  object_schema_name(parent_object_id)         AS table_schema,
            object_name(parent_object_id)                AS table_name,
            name                                         AS constraint_name,
            col_name(parent_object_id, parent_column_id) AS column_name,
            definition                                   AS constraint_definition
    FROM    sys.default_constraints
)
SELECT      *
FROM        cte_details AS d
            /*
            === to get specific table ===
            */
--WHERE       d.table_name = ''
ORDER BY    d.table_schema,
            d.table_name,
            d.constraint_name;
