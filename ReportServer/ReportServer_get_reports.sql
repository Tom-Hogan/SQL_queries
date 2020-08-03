/* ================================================================================================
Purpose:
    Lists all reports on current reporting instance.

History:
    2009-09-17  Tom Hogan           Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


SELECT      c.Path           AS report_path,
            c.Name           AS report_name,
            cbu.UserName     AS created_by,
            c.CreationDate   AS created_date,
            mbu.UserName     AS modified_by,
            c.ModifiedDate   AS modified_date,
            lre.InstanceName AS last_run_from,
            lre.UserName     AS last_run_by,
            lre.Format       AS last_run_format,
            lre.TimeStart    AS last_run_started,
            lre.TimeEnd      AS last_run_ended,
            lre.Status       AS last_run_status,
            lre.[RowCount]   AS last_run_row_count
FROM        dbo.Catalog         AS c
LEFT JOIN   dbo.Users           AS cbu  ON  cbu.UserID = c.CreatedByID
LEFT JOIN   dbo.Users           AS mbu  ON  mbu.UserID = c.ModifiedByID
            -- get last run time
LEFT JOIN   (
            SELECT      ReportID,
                        max(TimeStart) AS LastRunTime
            FROM        dbo.ExecutionLog
            GROUP BY    ReportID
            )                   AS lr   ON  lr.ReportID = c.ItemID
LEFT JOIN   dbo.ExecutionLog    AS lre  ON  lre.ReportID = lr.ReportID
                                        AND lre.TimeStart = lr.LastRunTime
WHERE       c.Type = 2  -- report
ORDER BY    c.Path,
            c.Name;
