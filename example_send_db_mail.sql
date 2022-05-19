/* ================================================================================================
Purpose:
    Examples of using sp_send_mail using HTML or Text formats.
 
History:
    2015-07-08  Tom Hogan           Created.
================================================================================================ */
DECLARE @table_results nvarchar(MAX);

/*
    html format
*/
/* build table */
SET @table_results =
    N'<h2>Posted Orders</h2>' + N'<table border = "1" width = "80%">' + N'<tr>'
    + N'<th> Invoice Date </th><th> Order Number </th><th> Item Number </th><th> Extended Total </th><th> Extended Cost </th><th> Quantity </th>' + N'</tr>'
    + cast(
      (
          SELECT    TOP ( 10 )
                    s.invoice_date   AS td, '',
                    s.order_number   AS td, '',
                    s.item_number    AS td, '',
                    s.extended_total AS td, '',
                    s.extended_cost  AS td, '',
                    s.quantity       AS td, ''
          FROM      dbo.fact_sales AS s
          WHERE     s.invoice_date = '20130610'
          FOR XML PATH('tr'), TYPE
      ) AS nvarchar(MAX)) + N'</table>';


/* send email */
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DatabaseMail',
    @recipients = 'test@thecompany.com',
    @subject = 'DB Send Mail Test - HTML',
    @body = @table_results,
    @body_format = 'HTML';


/* 
    text format (attached as file)
*/
/* send email */
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DatabaseMail',
    @recipients = 'test@thecompany.com',
    @subject = 'DB Send Mail Test - Text',
    @attach_query_result_as_file = 1,
    @query_attachment_filename = 'invoiced_sales.txt',
    @execute_query_database = 'Data_warehouse',
    @query = '
        SELECT  TOP ( 10 )
                s.invoice_date,
                s.order_number,
                s.item_number,
                s.extended_total,
                s.extended_cost,
                s.quantity
        FROM    dbo.fact_sales  AS s
        WHERE   s.invoice_date = ''20130610''';
