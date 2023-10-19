/* ================================================================================================
Purpose:
    Lists all messages associated with a given execution ID.

Notes:
    Contains some commented out predefined WHERE clauses.

History:
    2015-02-27  Tom Hogan           Created, based on work done by Jamie Thomson.
================================================================================================ */
USE SSISDB;
SET NOCOUNT ON;


DECLARE @execution_id int;

SET @execution_id = 0;


WITH
cte_events AS
(
    SELECT  em.event_message_id,
            em.message_time,
            em.message,
            replace(em.package_name, '.dtsx', '') AS package_name,
            em.event_name,
            em.message_source_name,
            em.package_path,
            em.execution_path   /*,
            cast(
            (
                SELECT  context.property_name,
                        context.property_value,
                        context.context_depth,
                        context.package_path,
                        CASE
                            WHEN context.context_type = 10
                                THEN 'Task'
                            WHEN context.context_type = 20
                                THEN 'Pipeline'
                            WHEN context.context_type = 30
                                THEN 'Sequence'
                            WHEN context.context_type = 40
                                THEN 'For Loop'
                            WHEN context.context_type = 50
                                THEN 'Foreach Loop'
                            WHEN context.context_type = 60
                                THEN 'Package'
                            WHEN context.context_type = 70
                                THEN 'Variable'
                            WHEN context.context_type = 80
                                THEN 'Connection manager'
                            ELSE NULL
                        END    AS context_type_desc,
                        context.context_source_name
                FROM    catalog.event_message_context AS context
                WHERE   context.event_message_id = em.event_message_id
                FOR XML AUTO
            ) AS xml)                             AS message_context    */
    FROM    catalog.event_messages AS em
    WHERE   em.operation_id = @execution_id
    AND     em.event_name NOT LIKE '%Validate%'
)
SELECT      *
FROM        cte_events AS e
            /* 
            === add / modify as needed ====
            */
--WHERE       e.event_name IN ( 'OnError', 'OnTaskFailed', 'OnWarning' )
--WHERE       e.event_name IN ( 'OnPostExecute', 'OnPreExecute' )
--WHERE       e.package_name = 'Package'
--WHERE       e.execution_path LIKE '%<some_executable>%'
ORDER BY    e.message_time DESC,
            e.event_message_id DESC;
