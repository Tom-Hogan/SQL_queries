/* ================================================================================================
Purpose:
    Returns synonyms and the objects they reference.

History:
    2010-08-26  Tom Hogan           Created.
================================================================================================ */
SELECT      schema_name(schema_id)                                             AS synonym_schema,
            name                                                               AS synonym_name,
            coalesce(parsename(base_object_name, 4), @@servername)             AS server_name,
            coalesce(parsename(base_object_name, 3), db_name(db_id()))         AS database_name,
            coalesce(parsename(base_object_name, 2), schema_name(schema_id())) AS schema_name,
            parsename(base_object_name, 1)                                     AS object_name
FROM        sys.synonyms
ORDER BY    synonym_schema,
            synonym_name;
