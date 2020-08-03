/* ================================================================================================
Purpose:
    Lists reports that have not been executed against current reporting instance.

History:
    2013-10-11  Tom Hogan           Created.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


SELECT      c.Path      AS report_path,
            c.Name      AS report_name,
            u.UserName  AS created_by
FROM        dbo.Catalog     AS c
LEFT JOIN   dbo.Users       AS u    ON  u.UserID = c.CreatedByID
WHERE       c.Type = 2  -- report
AND         NOT EXISTS  (
                        SELECT  1
                        FROM    dbo.ExecutionLog AS l
                        WHERE   l.ReportID = c.ItemID
                        )
ORDER BY    c.Path;
