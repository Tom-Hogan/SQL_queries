/* ================================================================================================
Purpose:
    Lists notifications on current reporting instance.

    *** Uncomment and update WHERE clause to filter results for a specific report.

History:
    2015-08-18  Tom Hogan           Created, based on a script by Dean Kalanquin on MSDN.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


SELECT      c.Path                                                                        AS report_path,
            uo.UserName                                                                   AS subscription_owner,
            s.Description                                                                 AS subscription_description,
            n.SubscriptionLastRunTime                                                     AS subscription_last_run,
            dateadd(HOUR, datediff(HOUR, getutcdate(), getdate()), n.NotificationEntered) AS notification_entered,
            dateadd(HOUR, datediff(HOUR, getutcdate(), getdate()), n.ProcessStart)        AS process_start,
            dateadd(HOUR, datediff(HOUR, getutcdate(), getdate()), n.ProcessAfter)        AS process_after,
            n.Attempt                                                                     AS attempt,
            dateadd(HOUR, datediff(HOUR, getutcdate(), getdate()), n.ProcessHeartbeat)    AS process_heart_beat,
            n.Version                                                                     AS version,
            n.IsDataDriven                                                                AS is_data_driven,
            n.SubscriptionID                                                              AS subscription_id,
            um.UserName                                                                   AS modified_by,
            s.ModifiedDate                                                                AS modified_datetime
FROM        dbo.Notifications   AS n
JOIN        dbo.Subscriptions   AS s    ON  n.SubscriptionID = s.SubscriptionID
JOIN        dbo.Catalog         AS c    ON  c.ItemID = n.ReportID
JOIN        dbo.Users           AS uo   ON  uo.UserID = s.OwnerID
JOIN        dbo.Users           AS um   ON  um.UserID = s.ModifiedByID
            -- ------------------------------------------------------------------------------------------------
            -- to get specific report
            -- ------------------------------------------------------------------------------------------------
--WHERE       c.Name = 'report_name'
ORDER BY    n.NotificationEntered DESC;
