/* ================================================================================================
Purpose:
    Returns details related to primary key / unique constraints.

    *** Uncomment and update WHERE clause to filter for a specific table.

History:
    2016-10-19  Tom Hogan           Created, based on script by Phil Factor.
================================================================================================ */

SELECT      object_schema_name(pk.parent_object_id)  AS table_schema,
            object_name(pk.parent_object_id)         AS table_name,
            pk.name                                  AS constraint_name,
            replace(pk.type_desc, '_CONSTRAINT', '') AS constraint_type,
            coalesce(stuff((
                           SELECT   ', ' + col_name(ic.object_id, ic.column_id) 
                                        +   CASE
                                                WHEN ic.is_descending_key <> 0
                                                THEN ' DESC'
                                                ELSE ''
                                            END
                           FROM     sys.index_columns   AS ic
                           WHERE    ic.index_id = pk.unique_index_id
                           AND      ic.object_id = pk.parent_object_id
                           AND      ic.is_included_column = 0
                           ORDER BY ic.key_ordinal
                           FOR XML PATH(''), TYPE
                           ).value('.', 'varchar(max)'), 1, 2, ''
                          ), '?'
                    )                                AS pk_columns,
            CASE
                WHEN pk.is_system_named = 1
                    THEN 'Yes'
                ELSE 'No'
            END                                      AS is_system_named,
            CASE
                WHEN objectpropertyex(pk.object_id, 'CnstIsClustKey') = 1
                    THEN 'Yes'
                ELSE 'No'
            END                                      AS is_pk_clustered
FROM        sys.key_constraints AS pk
WHERE       objectpropertyex(pk.parent_object_id, 'IsUserTable') = 1
            -- -------------------------------------------------------------------------------------------------
            -- to get specific table
            -- -------------------------------------------------------------------------------------------------
--AND         object_name(pk.parent_object_id) = 'fact_sales'
ORDER BY    table_schema,
            table_name,
            constraint_name
;
