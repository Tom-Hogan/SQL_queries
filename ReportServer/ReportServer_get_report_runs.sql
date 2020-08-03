/* ================================================================================================
Purpose:
    Lists report executions against current reporting instance.

    *** Uncomment and update WHERE clause to filter results for a specific report.

History:
    2011-08-03  Tom Hogan           Created.
    2015-08-17  Tom Hogan           Updated to use custom view.
================================================================================================ */
USE ReportServer;
SET NOCOUNT ON;


SELECT      e.instance_name,
            e.item_path,
            e.report_name,
            e.run_by,
            e.request_type,
            e.format                                                       AS report_format,
            cast((
                 SELECT token AS parameter
                 FROM   dbo.Split_String_XML(e.parameters, N'&')
                 FOR XML PATH(''), ELEMENTS
                 ) AS xml)                                                 AS report_parameters,
            e.time_start,
            e.time_end,
            e.time_to_retrieve_data,
            e.time_to_process,
            e.time_to_render,
            e.time_to_retrieve_data + e.time_to_process + e.time_to_render AS run_time,
            e.run_status,
            e.row_count
FROM        dbo.custom_execution_log    AS e
            -- ------------------------------------------------------------------------------------------------
            -- to get specific report
            -- ------------------------------------------------------------------------------------------------
--WHERE       e.report_name = 'report_name'
ORDER BY    e.time_start DESC;
