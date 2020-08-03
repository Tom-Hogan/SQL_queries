/* ================================================================================================
Purpose:
    Lists all database mail activity for a given time period. Also checks the logs against the same 
    time period.

    *** Uncomment and update WHERE clause to filter for a specific period of time or a specific
        mail item ID (depending on query)

History:
    2012-08-15  Tom Hogan           Created.
================================================================================================ */
USE msdb;


-- get all database mail items
SELECT      i.mailitem_id               AS mail_item_id,
            i.sent_date,
            i.sent_status,
            i.sent_account_id,
            i.profile_id,
            i.subject,
            i.recipients,
            isnull(l.description, '')   AS [description]
FROM        dbo.sysmail_allitems    AS i
LEFT JOIN   dbo.sysmail_event_log   AS l    ON  l.mailitem_id = i.mailitem_id
            -- ------------------------------------------------------------------------------------------------
            -- to get a specific period of time, format yyyymmdd
            -- ------------------------------------------------------------------------------------------------
--WHERE       i.sent_date >= '20120808'
--AND         i.sent_date < '20120809'
ORDER BY    i.send_request_date DESC
;


/*
-- check database mail log
SELECT      log_id,
            log_date,
            description,
            event_type,
            mailitem_id AS mail_item_id,
            process_id,
            account_id
FROM        dbo.sysmail_event_log
            -- ------------------------------------------------------------------------------------------------
            -- to get a specific mail item ID 
            -- ------------------------------------------------------------------------------------------------
--WHERE       mailitem_id = 29
ORDER BY    log_date DESC
;
-- */

/*
-- purge mail data older than 90 days

DECLARE @cleanup_start_date datetime = ( SELECT dateadd(d, -90, getdate()) );
EXEC dbo.sysmail_delete_mailitems_sp @sent_before = @cleanup_start_date;
EXEC dbo.sysmail_delete_log_sp @logged_before = @cleanup_start_date;
-- */
