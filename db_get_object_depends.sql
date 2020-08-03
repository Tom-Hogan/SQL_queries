/* ================================================================================================
Purpose:
    Returns all objects that are used by a given procedure / function call.

    *** Uncomment and update WHERE clause to filter for procedure(s) / function(s) to check.
 
History:
    2005-04-14  Tom Hogan           Created.
    2007-07-05  Tom Hogan           Updated to use sys views.
================================================================================================ */

WITH cte_references
AS
    (
    -- get list of objects that are referenced directly by the procedure / function
    SELECT      ed.referenced_id,
                schema_name(o.schema_id)      AS schema_name,
                o.name                        AS object_name,
                o.type_desc                   AS object_type,
                ed.referenced_database_name,
                ed.referenced_schema_name,
                ed.referenced_entity_name     AS referenced_object_name,
                ro.type_desc                  AS referenced_object_type,
                1                             AS reference_level,
                cast(o.name AS varchar(4000)) AS dependency_path
    FROM        sys.objects                     AS o
    JOIN        sys.sql_expression_dependencies AS ed   ON  ed.referencing_id = o.object_id
    LEFT JOIN   sys.objects                     AS ro   ON  ro.object_id = ed.referenced_id
    -- ------------------------------------------------------------------------------------------------
    -- enter list of objects
    -- ------------------------------------------------------------------------------------------------
    --WHERE       o.name IN ('')
    UNION ALL
    SELECT  ed.referenced_id,
            schema_name(o.schema_id)                                                         AS schema_name,
            o.name                                                                           AS object_name,
            o.type_desc                                                                      AS object_type,
            ed.referenced_database_name,
            ed.referenced_schema_name,
            ed.referenced_entity_name                                                        AS referenced_object_name,
            ro.type_desc                                                                     AS referenced_object_type,
            r.reference_level + 1                                                            AS reference_level,
            cast(r.dependency_path + ' | ' + cast(o.name AS varchar(4000)) AS varchar(4000)) AS dependency_path
    FROM    cte_references                  AS r
    JOIN    sys.objects                     AS o    ON  o.object_id = r.referenced_id
    JOIN    sys.sql_expression_dependencies AS ed   ON  ed.referencing_id = o.object_id
    JOIN    sys.objects                     AS ro   ON  ro.object_id = ed.referenced_id
    WHERE   r.referenced_object_type LIKE 'SQL%'
    )
SELECT      schema_name,
            object_name,
            object_type,
            referenced_database_name,
            referenced_object_name,
            referenced_object_type,
            reference_level,
            dependency_path
FROM        cte_references
ORDER BY    reference_level,
            schema_name,
            object_name,
            referenced_object_type
;
