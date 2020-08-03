CREATE OR ALTER FUNCTION dbo.clean_string (
    @string  varchar(8000),

    -- 1. Case sensitive.
    -- 2. The pattern set of characters must be for just one character.
    @pattern varchar(100)
)
RETURNS varchar(8000)
AS
/* ================================================================================================
Purpose:
    Given a string and a pattern of characters to remove, remove the patterned characters from the string.

Example:
    -- Basic Syntax
    SELECT  dbo.clean_string(@some_string, @pattern);

    -- Remove all but Alpha characters
    SELECT  dbo.clean_string(st.some_string,'%[^A-Za-z]%')  AS cleaned_string
    FROM    dbo.Some_Table  AS st;

    -- Remove all but Numeric digits
    SELECT  dbo.clean_string(st.some_string,'%[^0-9]%')     AS cleaned_string
    FROM    dbo.Some_Table  AS st;

History:
    Circa 2007  Author Unknown      (Rev 00) Initial find on the web
    2007-29-03  Jeff Moden          (Rev 01) - Optimize to remove one instance of PATINDEX from the loop.
                                             - Add code to use the pattern as a parameter.
    2013-05-26  Jeff Moden          (Rev 02) Add case sensitivity
    2018-06-07  Tom Hogan                    Formatting.
================================================================================================ */
BEGIN
    DECLARE @position smallint;

    -- get starting position for pattern
    SELECT  @position = patindex(@pattern, @string COLLATE Latin1_General_BIN);

    -- work through string
    WHILE @position > 0
        SELECT  @string   = stuff(@string, @position, 1, ''),
                @position = patindex(@pattern, @string COLLATE Latin1_General_BIN);

    RETURN @string;
END;

GO
