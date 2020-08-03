CREATE OR ALTER FUNCTION dbo.split_string_tally (
    @list      nvarchar(MAX),
    @delimiter nvarchar(2)
)
RETURNS table
WITH SCHEMABINDING
AS
/* ================================================================================================
Purpose:
    Splits strings containing multiple values delimited by specific character(s).
     - Uses Tally table to split the values for improved performance.
     - Returns in table form.

Example:
    SELECT * FROM dbo.split_string_tally('Patriots,Red Sox,Bruins', ',')

History:
    Taken from http://sqlperformance.com/2012/07/t-sql-queries/split-strings.
================================================================================================ */
RETURN 

SELECT  ltrim(rtrim(substring(@list, n, charindex(@delimiter, @list + @delimiter, n) - n)))     AS token,
        row_number() OVER ( ORDER BY ( SELECT 0 ))                                              AS ordinal
FROM    dbo.tally
WHERE   n <= convert(int, len(@list))
AND     substring(@delimiter + @list, n, len(@delimiter)) = @delimiter;

GO
