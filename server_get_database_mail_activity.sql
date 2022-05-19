/* ================================================================================================
Purpose:
    Lists all database mail activity for a given time period. Also checks the logs against the same 
    time period.

Notes:
     * Contains commented out predefined WHERE clauses:
        - For all mail items, can filter results for a specific period of time.
        - For mail log, can filter for a specific mail item ID.
     * Contains a section (commented out) with command to purge database mails history.

History:
    2012-08-15  Tom Hogan           Created.
================================================================================================ */
USE msdb;


/* get all database mail items */
SELECT      ai.mailitem_id             AS mail_item_id,
            ai.sent_date,
            ai.sent_status,
            ai.sent_account_id,
            ai.profile_id,
            ai.subject,
            ai.recipients,
            isnull(el.description, '') AS description
FROM        dbo.sysmail_allitems    AS ai
LEFT JOIN   dbo.sysmail_event_log   AS el   ON  el.mailitem_id = ai.mailitem_id
            /*
            === to get a specific period of time, format yyyymmdd===
            */
--WHERE       ai.sent_date >= '20120808'
--AND         ai.sent_date < '20120809'
ORDER BY    ai.send_request_date DESC;


/*
/* check database mail log */
SELECT      log_id,
            log_date,
            description,
            event_type,
            mailitem_id AS mail_item_id,
            process_id,
            account_id
FROM        dbo.sysmail_event_log
            /*
            === to get a specific period of time, format yyyymmdd===
            */
WHERE       mailitem_id = 29
ORDER BY    log_date DESC;
-- */

/*
/* purge mail data older than 90 days */
DECLARE @cleanup_start_date datetime =
            (
                SELECT  dateadd(d, -90, getdate())
            );

EXEC dbo.sysmail_delete_mailitems_sp
    @sent_before = @cleanup_start_date;
EXEC dbo.sysmail_delete_log_sp
    @logged_before = @cleanup_start_date;
-- */
