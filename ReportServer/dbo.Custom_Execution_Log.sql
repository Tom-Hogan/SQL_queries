USE ReportServer;
GO

CREATE OR ALTER VIEW dbo.custom_execution_log
AS
/* ================================================================================================
Purpose:
    View to get report execution details from ReportServer (SSRS) databases.
     - Based on ExecutionLog3 view in SSRS 2012.

History:
    2010-03-10  Tom Hogan           Created.
================================================================================================ */
    SELECT      e.InstanceName                                                                                     AS instance_name,
                coalesce(c.Path, 'Unknown')                                                                        AS item_path,
                c.Name                                                                                             AS report_name,
                e.UserName                                                                                         AS run_by,
                e.ExecutionId                                                                                      AS execution_id,
                CASE e.RequestType
                    WHEN 0 THEN 'Interactive'
                    WHEN 1 THEN 'Subscription'
                    WHEN 2 THEN 'Refresh Cache'
                    ELSE 'Unknown'
                END                                                                                                AS request_type,
                e.Format                                                                                           AS format,
                replace(replace(replace(cast(e.Parameters AS nvarchar(MAX)), '%2F', '/'), '%3A', ':'), '%20', ' ') AS parameters,
                CASE e.ReportAction
                    WHEN 1 THEN 'Render'
                    WHEN 2 THEN 'BookmarkNavigation'
                    WHEN 3 THEN 'DocumentMapNavigation'
                    WHEN 4 THEN 'DrillThrough'
                    WHEN 5 THEN 'FindString'
                    WHEN 6 THEN 'GetDocumentMap'
                    WHEN 7 THEN 'Toggle'
                    WHEN 8 THEN 'Sort'
                    WHEN 9 THEN 'Execute'
                    ELSE 'Unknown'
                END                                                                                                AS item_action,
                e.TimeStart                                                                                        AS time_start,
                e.TimeEnd                                                                                          AS time_end,
                e.TimeDataRetrieval                                                                                AS time_to_retrieve_data,
                e.TimeProcessing                                                                                   AS time_to_process,
                e.TimeRendering                                                                                    AS time_to_render,
                CASE e.Source
                    WHEN 1 THEN 'Live'
                    WHEN 2 THEN 'Cache'
                    WHEN 3 THEN 'Snapshot'
                    WHEN 4 THEN 'History'
                    WHEN 5 THEN 'AdHoc'
                    WHEN 6 THEN 'Session'
                    WHEN 7 THEN 'Rdce'
                    ELSE 'Unknown'
                END                                                                                                AS source,
                e.Status                                                                                           AS run_status,
                e.ByteCount                                                                                        AS byte_count,
                e.[RowCount]                                                                                       AS row_count,
                e.AdditionalInfo                                                                                   AS additional_info,
                cbu.UserName                                                                                       AS created_by,
                c.CreationDate                                                                                     AS created_date,
                mbu.UserName                                                                                       AS modified_by,
                c.ModifiedDate                                                                                     AS modified_date --,
                /*
                -- ------------------------------------------------------------------------------------------------
                -- for informational purposes
                -- ------------------------------------------------------------------------------------------------
                CASE c.type
                    WHEN 1 THEN 'Folder'
                    WHEN 2 THEN 'Report'
                    WHEN 3 THEN 'XML'
                    WHEN 4 THEN 'Linked Report'
                    WHEN 5 THEN 'Data Source'
                    WHEN 6 THEN 'Model'
                    WHEN 8 THEN 'Shared Dataset'
                    WHEN 9 THEN 'Report Part'
                END                                                                                                AS type_description
                -- */
    FROM        dbo.ExecutionLogStorage AS e
    LEFT JOIN   dbo.Catalog             AS c    ON  c.ItemID = e.ReportID
    LEFT JOIN   dbo.Users               AS cbu  ON  cbu.UserID = c.CreatedByID
    LEFT JOIN   dbo.Users               AS mbu  ON  mbu.UserID = c.ModifiedByID;

GO
