/* ================================================================================================
Purpose:
    Returns trigger details.
 
History:
    2004-11-15  Tom Hogan           Created.
    2007-07-05  Tom Hogan           Updated to use sys views.
================================================================================================ */
SELECT      coalesce(object_schema_name(tr.parent_id) + '.' + object_name(tr.parent_id), 'Database (' + db_name() + ')') AS parent_name,
            tr.name                                                                                                      AS trigger_name,
            objectproperty(tr.object_id, 'ExecIsUpdateTrigger')                                                          AS is_update,
            objectproperty(tr.object_id, 'ExecIsDeleteTrigger')                                                          AS is_delete,
            objectproperty(tr.object_id, 'ExecIsInsertTrigger')                                                          AS is_insert,
            objectproperty(tr.object_id, 'ExecIsAfterTrigger')                                                           AS is_after,
            tr.is_instead_of_trigger                                                                                     AS is_instead_of,
            tr.is_disabled
FROM        sys.triggers    AS tr
WHERE       tr.is_ms_shipped = 0    /* user created */
ORDER BY    parent_name,
            trigger_name;
