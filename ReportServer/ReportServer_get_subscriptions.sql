/* ================================================================================================
Purpose:
    Lists subscriptions on current reporting instance.

    *** Uncomment and update WHERE clause to filter results for a specific report.

History:
    2012-11-07  Tom Hogan           Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


SELECT      c.Path                      AS report_path,
            s.Description               AS subscription_description,
            s.EventType                 AS subscription_type,
            uo.UserName                 AS subscription_owner,
            cast(s.Parameters AS xml)   AS parameters_xml,
            replace(replace(cast(cast(s.ExtensionSettings AS xml).query('/ParameterValues/ParameterValue/Value[../Name = ''TO'']') AS varchar(4000)), '</Value>', '; '), '<Value>', '')     AS to_recipients,
            replace(replace(cast(cast(s.ExtensionSettings AS xml).query('/ParameterValues/ParameterValue/Value[../Name = ''CC'']') AS varchar(4000)), '</Value>', '; '), '<Value>', '')     AS cc_recipients,
            replace(replace(cast(cast(s.ExtensionSettings AS xml).query('/ParameterValues/ParameterValue/Value[../Name = ''BCC'']') AS varchar(4000)), '</Value>', '; '), '<Value>', '')    AS bcc_recipients,
            s.LastRunTime               AS last_run_time,
            s.LastStatus                AS last_run_status,
            --rs.ScheduleID               AS schedule_id,
            --s.SubscriptionID            AS subscription_id,
            CASE
                WHEN j.name <> ''
                    THEN 'Yes'
                ELSE 'No'
            END                         AS job_exists,
            um.UserName                 AS modified_by,
            s.ModifiedDate              AS modified_datetime
FROM        dbo.Subscriptions   AS s
JOIN        dbo.Catalog         AS c    ON  c.ItemID = s.Report_OID 
JOIN        dbo.ReportSchedule  AS rs   ON  rs.SubscriptionID = s.SubscriptionID
JOIN        dbo.Users           AS uo   ON  uo.UserID = s.OwnerID 
JOIN        dbo.Users           AS um   ON  um.UserID = s.ModifiedByID 
LEFT JOIN   msdb.dbo.sysjobs    AS j    ON  j.name = convert(nvarchar(128), rs.ScheduleID) 
            -- ------------------------------------------------------------------------------------------------
            -- to get specific report
            -- ------------------------------------------------------------------------------------------------
--WHERE       c.name = 'report_name'
ORDER BY    c.Path,
            s.Description;
