/* ================================================================================================
Purpose:
    Returns tables and columns that are part of a foreign key relationship.
 
History:
    2005-05-03  Tom Hogan           Created.
    2007-07-05  Tom Hogan           Updated to use 2005 sys views.
    2015-06-09  Tom Hogan           Added On Delete / On Update action columns.
================================================================================================ */
SELECT      fk.name                                                         AS foreign_key,
            object_name(fk.parent_object_id)                                AS fk_table,
            col_name(fkc.parent_object_id, fkc.parent_column_id)            AS fk_column,
            object_name(fk.referenced_object_id)                            AS referenced_table,
            col_name(fkc.referenced_object_id, fkc.referenced_column_id)    AS referenced_column,
            fk.delete_referential_action_desc                               AS on_delete_action,
            fk.update_referential_action_desc                               AS on_update_action,
            CASE
                WHEN count(*) OVER ( PARTITION BY fk.name
                                     ORDER BY fk.name
                                   ) > 1
                    THEN 1
                ELSE 0
            END                                                             AS is_composite_key,
            isnull(objectproperty(object_id(fk.name), 'CnstIsDisabled'), 0) AS is_disabled,
            fk.is_not_trusted
FROM        sys.foreign_keys        AS fk
JOIN        sys.foreign_key_columns AS fkc  ON  fkc.constraint_object_id = fk.object_id
ORDER BY    fk_table,
            foreign_key;
