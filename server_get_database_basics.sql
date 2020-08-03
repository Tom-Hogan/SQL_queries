/* ================================================================================================
Purpose:
    Lists basic data about databases.
 
History:
    2012-09-04  Tom Hogan           Created.
================================================================================================ */
USE master;


SELECT      database_id,
            name,
            suser_sname(owner_sid)      AS database_owner,
            recovery_model_desc,
            compatibility_level,
            state_desc,
            user_access_desc,
            collation_name,
            log_reuse_wait_desc,
            page_verify_option_desc     AS page_verify_option,
            is_auto_create_stats_on,
            is_auto_update_stats_on,
            is_auto_shrink_on,
            create_date
FROM        sys.databases
WHERE       name NOT IN ('master', 'model', 'msdb', 'tempdb')
ORDER BY    name
;
