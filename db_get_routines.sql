/* ================================================================================================
Purpose:
    Returns details about all modules (functions and procedures).
 
History:
    2004-12-06  Tom Hogan           Created.
    2015-07-22  Tom Hogan           Updated to use sys views.
================================================================================================ */
SELECT      s.name                           AS module_schema,
            o.name                           AS module_name,
            o.type                           AS module_type_code,
            replace(o.type_desc, 'SQL_', '') AS module_type,
            o.modify_date                    AS last_modified_datetime
FROM        sys.sql_modules AS sm
JOIN        sys.objects     AS o    ON  o.object_id = sm.object_id
                                    AND o.is_ms_shipped = 0
                                    AND o.type IN ('P', 'FN', 'IF', 'TF')
JOIN        sys.schemas     AS s    ON  s.schema_id = o.schema_id
ORDER BY    module_schema,
            module_type,
            module_name;
