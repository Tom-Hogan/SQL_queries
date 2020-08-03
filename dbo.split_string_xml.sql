CREATE OR ALTER FUNCTION dbo.split_string_xml (
    @list      nvarchar(MAX),
    @delimiter nvarchar(2)
)
RETURNS table
WITH SCHEMABINDING
AS
/* ================================================================================================
Purpose:
    Splits strings containing multiple values delimited by specific character(s).
     - Uses XML to split the values.
     - Returns in table form.

Example:
    SELECT * FROM dbo.split_string_xml('Patriots,Red Sox,Bruins', ',')

History:
    Taken from http://sqlperformance.com/2012/07/t-sql-queries/split-strings.
================================================================================================ */
RETURN 

SELECT      ltrim(rtrim(y.i.value('(./text())[1]', 'nvarchar(4000)')))  AS token,
            row_number() OVER ( ORDER BY ( SELECT 0 ))                  AS ordinal
FROM        (
            SELECT  convert(xml, '<i>' + replace(@list, @delimiter, '</i><i>') + '</i>').query('.') AS x
            )            AS a
CROSS APPLY x.nodes('i') AS y(i);

GO
