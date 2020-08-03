/* ================================================================================================
Purpose:
    Returns objects that contain a specific string.

    *** 1. Update WHERE clause with the string you want to find.  
        2. Leave the % before and after the search string.
 
History:
    2006-06-20  Tom Hogan           Created.
    2007-07-05  Tom Hogan           Updated to use sys views.
================================================================================================ */

SELECT      DISTINCT
            schema_name(o.schema_id) + '.' + o.name AS [object_name],
            o.type_desc                             AS object_type
FROM        sys.all_sql_modules AS m
JOIN        sys.all_objects     AS o    ON  o.object_id = m.object_id
                                            -- check only non-Microsoft objects
                                        AND o.is_ms_shipped = 0
            -- ------------------------------------------------------------------------------------------------
            -- update with string to find
            -- ------------------------------------------------------------------------------------------------
WHERE       m.definition LIKE '%grant%'
ORDER BY    object_type,
            object_name
;
