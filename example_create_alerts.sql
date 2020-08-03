/* ================================================================================================
Purpose:
    Example commands to create alerts related to the health of a SQL Server, as well as alerts
    for corruption.

    *** Update the Operator name with who should get the alerts.
 
History:
    2004-12-16  Tom Hogan           Created.  Based on work done by Brent Ozar
                                    https://www.brentozar.com/blitz/configure-sql-server-alerts/
================================================================================================ */

-- ------------------------------------------------------------------------------------------------
-- Severity 017 - Insufficient resources-
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert 
    @name = N'Severity 017',
    @message_id = 0,
    @severity = 17,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Severity 017',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 018 - Nonfatal internal error
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 018',
    @message_id = 0,
    @severity = 18,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Severity 018',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 019 - Fatal error in resource
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert 
    @name = N'Severity 019', 
    @message_id = 0,
    @severity = 19, 
    @enabled = 1,
    @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Severity 019', 
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 020 - Fatal error in current process
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert 
    @name = N'Severity 020', 
    @message_id = 0,
    @severity = 20,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Severity 020',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 021 - Fatal error in database processes
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 021',
    @message_id = 0,
    @severity = 21,
    @enabled = 1,
    @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Severity 021',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 022 - Fatal error: Table integrity suspect
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 022',
    @message_id = 0,
    @severity = 22,
    @enabled = 1,
    @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Severity 022',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 023 - Fatal error: Database integrity suspect
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 023',
    @message_id = 0,
    @severity = 23,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Severity 023',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 024 - Fatal error: Hardware error
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 024',
    @message_id = 0,
    @severity = 24,
    @enabled = 1,
    @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Severity 024',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Severity 025 - Fatal error
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Severity 025',
    @message_id = 0,
    @severity = 25,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Severity 025',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Error 823 - IO error: OS cannot read the data.
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Error 823',
    @message_id = 823,
    @severity = 0,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Error 823',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Error 824 - IO error: SQL Server cannot read the data.
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Error 824',
    @message_id = 824,
    @severity = 0,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Error 824',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;


-- ------------------------------------------------------------------------------------------------
-- Error 825 - IO error: SQL Server took multiple attempts to read the data
-- ------------------------------------------------------------------------------------------------
EXEC msdb.dbo.sp_add_alert
    @name = N'Error 825',
    @message_id = 825,
    @severity = 0,
    @enabled = 1,
    @include_event_description_in = 1;

EXEC msdb.dbo.sp_add_notification 
    @alert_name = N'Error 825',
    @operator_name = N'SQL_Alerts',
    @notification_method = 1;
