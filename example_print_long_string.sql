/* ================================================================================================
Purpose:
    Example of how to "print" the contents of a long string in SSMS as the PRINT statement is limited
    to 8000 characters.
 
History:
    2018-05-15  Tom Hogan           Created, based on article Adam Machanic.
================================================================================================ */

SELECT  @sql_command1 AS [processing-instruction(x)]
FOR XML PATH('');