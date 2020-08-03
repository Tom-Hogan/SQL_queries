CREATE OR ALTER FUNCTION dbo.check_non_printable_character (
    @string varchar(8000)
)
RETURNS int
AS
/* ================================================================================================
Purpose:
    Checks the input for non-printable characters like TAB, LF, BS.
     - Returns 1 if any are found, 0 otherwise.

Example:
    SELECT  dbo.check_non_printable_character(@some_string);

History:
    2011-02-21  Tom Hogan           Created (based on script by Damien Alvarado; damien.alvarado at parivedasolutions dot com).
================================================================================================ */
BEGIN
    DECLARE @position         int,
            @length           int,
            @ascii_value      int,
            @is_bad_character int;

    -- set initial values
    SET @position = 1;
    SET @length = len(@string);
    SET @is_bad_character = 0;


    -- Check each character in the string for non-printable characters
    WHILE @position <= @length
    AND   @is_bad_character = 0
    BEGIN
        SET @ascii_value = ascii(substring(@string, @position, 1));

        -- range of printable ASCII characters is between 32 and 126
        IF  @ascii_value < 32
        OR  @ascii_value > 126
        BEGIN
            SET @is_bad_character = 1;
        END;

        SET @position = @position + 1;
    END;

    RETURN @is_bad_character;

END;

GO
