/* ================================================================================================
Purpose:
    Returns constraint information.

    *** Uncomment and update WHERE clause to filter for a specific table.
 
History:
    2004-12-06  Tom Hogan           Created.
    2015-07-22  Tom Hogan           Updated to use sys views.
    2016-10-19  Tom Hogan           Updated to pull from sys.objects only.
================================================================================================ */

SELECT      object_schema_name(parent_object_id)  AS table_schema,
            object_name(parent_object_id)         AS table_name,
            name                                  AS constraint_name,
            replace(type_desc, '_CONSTRAINT', '') AS constraint_type,
            CASE
                WHEN objectproperty(object_id(name), 'CnstIsDisabled') = 1
                    THEN 'Yes'
                ELSE 'No'
            END                                   AS is_disbled
FROM        sys.objects
WHERE       objectpropertyex(object_id, 'IsConstraint') = 1
            -- ------------------------------------------------------------------------------------------------
            -- to get specific table
            -- ------------------------------------------------------------------------------------------------
--AND         object_name(parent_object_id) = ''
ORDER BY    table_schema,
            table_name,
            constraint_name
;
