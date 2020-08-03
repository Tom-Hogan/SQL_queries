CREATE OR ALTER FUNCTION dbo.double_metaphone (
    @string      varchar(50),   -- a word
    @return_type tinyint        -- 1 = return primary metaphone, 2 = return alternative metaphone
)
RETURNS varchar(4)
AS
/* ================================================================================================
Purpose:
    Metaphone is a phonetic algorithm, published by Lawrence Philips in 1990, for indexing words by 
    their English pronunciation. The double metaphone implementation was described in the June 2000 
    issue of C/C++ Users Journal.  It can return both a primary and a secondary code for a string; 
    this accounts for some ambiguous cases as well as for multiple variants of surnames.

    Reduces alphabet to the 14 consonant sounds:
        "sh"                       "p"or"b" "th"
        |                             |     |
        X  S  K  J  T  F  H  L  M  N  P  R  0  W
    Drop vowels except at the beginning.

    Function returns a string representing either the primary or alternative Metaphone equivalent of 
    the word.  The alternative will return an empty string if it is equivalent to the primary.

    *** There is a line purposely commented out near the bottom of the 'C' section to match the 
        logic of the table function we incorrectly implemented.

Example:
    SELECT dbo.double_metaphone('stuff', 1)

History:
    2017-06-01  Tom Hogan           Based on the table function made by Tim Pfeiffer 
                                     - (http://sqlmag.com/t-sql/double-metaphone-sounds-great).
                                    It was too slow for our purposes. Grabbed the scalar function 
                                    by by Keith Henry (keithh_AT_lbm-solutions.com) and found that 
                                    it returned different results than the table function.  Leveraged 
                                    the two to build this function.
================================================================================================ */
BEGIN
    -- ------------------------------------------------------------------------------------------------
    -- variables
    -- ------------------------------------------------------------------------------------------------
    DECLARE @metaphone_1       varchar(4) = '',
            @metaphone_2       varchar(4) = '',
            @metaphone_value   varchar(4) = '',
            @position          int,
            @len               int,
            @current           char(1),
            @previous          char(1),
            @next              char(1),
            @following         char(1),
            @is_slavo_germanic tinyint;

    -- set initial values
    SET @position = 1;
    SET @is_slavo_germanic = 0;
    SET @len = len(@string);
    SET @string = upper(@string);


    -- ------------------------------------------------------------------------------------------------
    -- simple rules for the start of a string
    -- ------------------------------------------------------------------------------------------------
    IF  (   (charindex('W', @string)) > 0
        OR  (charindex('K', @string)) > 0
        OR  (charindex('CZ', @string)) > 0
        )
    BEGIN
        SET @is_slavo_germanic = 1;
    END;


    -- if string begins with 'GN', 'KN', 'PN', 'WR', 'PS', drop the first letter.
    IF substring(@string, 1, 2) IN ('GN', 'KN', 'PN', 'WR', 'PS')
    BEGIN
        SET @position = @position + 1;
    END;

    -- if string begins with 'X', transform to 'S'
    -- 'Deng Xiaopeng'
    IF left(@string, 1) = 'X'
    BEGIN
        SET @metaphone_1 = @metaphone_1 + 'S';
        SET @metaphone_2 = @metaphone_2 + 'S';
        SET @position = @position + 1;
    END;


    -- ------------------------------------------------------------------------------------------------
    -- work through the string
    --
    -- We drop a letter by ignoring it.  By increasing the value of the position counter by 1 (or more,
    -- depending on the rule), the character in that position(s) is not evaluated (i.e. ignored).
    -- ------------------------------------------------------------------------------------------------
    -- stop loop if we reach the end of the string or reach 4 characters for the primary metaphone value
    WHILE @position <= @len
    AND   len(@metaphone_1) <= 4
    AND   len(@metaphone_2) <= 4
    BEGIN
        -- get current character and those characters nearest to it
        SET @current = substring(@string, @position, 1);
        SET @next = substring(@string, (@position + 1), 1);
        SET @previous = substring(@string, (@position - 1), 1);
        SET @following = substring(@string, @position + 2, 1);


        -- if string starts with a vowel, set it to 'A'
        -- else drop it
        IF @current IN ('A', 'E', 'I', 'O', 'U', 'Y')
        BEGIN
            IF @position = 1
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'A';
                SET @metaphone_2 = @metaphone_2 + 'A';
            END;

            SET @position = @position + 1;
        END;


        -- 'B' transforms to 'P'
        -- drop next character if it's 'B'
        -- '-MB' is handled in M section
        ELSE IF @current = 'B'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'P';
            SET @metaphone_2 = @metaphone_2 + 'P';

            IF @next = 'B'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'C' generally transforms to 'K' or 'S'
        -- there are a couple of case where it tranforms to 'KS', 'X', or 'S'
        -- check section comments for transformation rules
        ELSE IF @current = 'C'
        BEGIN
            --various Germanic
            IF  @position > 2
            AND substring(@string, @position - 2, 1) NOT IN ('A', 'E', 'I', 'O', 'U', 'Y')
            AND substring(@string, @position - 1, 3) = 'ACH'
            AND (   @following <> 'I'
                AND (   @following <> 'E'
                    OR  substring(@string, @position - 2, 6) IN ('BACHER', 'MACHER')
                    )
                )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'K';
                SET @position = @position + 2;
            END;
            -- 'Caesar'
            ELSE IF  @position = 1
                 AND substring(@string, @position, 6) = 'CAESAR'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'S';
                SET @metaphone_2 = @metaphone_2 + 'S';
                SET @position = @position + 2;
            END;
            -- 'Chianti'
            ELSE IF substring(@string, @position, 4) = 'CHIA'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'K';
                SET @position = @position + 2;
            END;
            ELSE IF @next = 'H'
            BEGIN
                -- 'Michael'
                IF  @position > 1
                AND substring(@string, @position, 4) = 'CHAE'
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'X';
                    SET @position = @position + 2;
                END;
                -- Greek roots; ex. 'chemistry', 'chorus'
                ELSE IF (   @position = 1
                        AND (   substring(@string, 2, 3) IN ('HOR', 'HYM', 'HIA', 'HEM')
                            OR  substring(@string, 2, 5) IN ('HARAC', 'HARIS')
                            )
                        AND substring(@string, 1, 5) <> 'CHORE'
                        )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'K';
                    SET @position = @position + 2;
                END;
                -- Germanic, Greek, or otherwise 'ch' for 'kh' sound
                ELSE IF (   substring(@string, 1, 4) IN ('VAN ', 'VON ')
                        OR  substring(@string, 1, 3) IN ('SCH')
                            -- 'architect' but not 'arch', orchestra', 'orchid'
                        OR  substring(@string, @position - 2, 6) IN ('ORCHES', 'ARCHIT', 'ORCHID')
                        OR  @following IN ('T', 'S')
                            -- 'Wachtler', 'Weschsler', but not 'Tichner'
                        OR (    (   @previous IN ('A', 'O', 'U', 'E')
                                OR  @position = 1
                                )
                            AND @following IN ('L', 'R', 'N', 'M', 'B', 'H', 'F', 'V', 'W', ' ')
                            )
                        )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'K';
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    IF @position > 1 -- is this a given?
                    BEGIN
                        -- 'McHugh'
                        IF substring(@string, 1, 2) = 'MC'
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'K';
                            SET @metaphone_2 = @metaphone_2 + 'K';
                        END;
                        ELSE
                        BEGIN
                            -- alternate encoding
                            SET @metaphone_1 = @metaphone_1 + 'X';
                            SET @metaphone_2 = @metaphone_2 + 'K';
                        END;
                    END;
                    ELSE
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'X';
                        SET @metaphone_2 = @metaphone_2 + 'X';
                    END;
                    SET @position = @position + 2;
                END;
            END; -- end 'CH'
            -- 'Czerny'
            ELSE IF  @next = 'Z'
                 AND substring(@string, @position - 2, 4) <> 'WICZ'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'S';
                SET @metaphone_2 = @metaphone_2 + 'X';
                SET @position = @position + 2;
            END;
            -- 'focaccia'
            ELSE IF substring(@string, @position + 1, 3) = 'CIA'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'X';
                SET @metaphone_2 = @metaphone_2 + 'X';
                SET @position = @position + 3;
            END;
            -- double 'C', but not 'McClellan'
            ELSE IF  @next = 'C'
                 AND NOT (   @position = 2
                         AND left(@string, 1) = 'M'
                         )
            BEGIN
                -- 'Bellocchio' but not 'Bacchus'
                IF  substring(@string, @position + 2, 1) IN ('I', 'E', 'H')
                AND substring(@string, @position + 2, 2) <> 'HU'
                BEGIN
                    IF  (   @position = 2
                        AND @previous = 'A'
                        )
                    OR  substring(@string, @position - 1, 5) IN ('UCCEE', 'UCCES')
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'KS';
                        SET @metaphone_2 = @metaphone_2 + 'KS';
                    END;
                    -- 'bacci', 'bertucci', other Italian
                    ELSE
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'X';
                        SET @metaphone_2 = @metaphone_2 + 'X';
                    END;
                    SET @position = @position + 3;
                END;
                -- Pierce's rule (who?)
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'K';
                    SET @position = @position + 2;
                END;
            END; -- end 'CC'
            ELSE IF @next IN ('K', 'G', 'Q')
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'K';
                SET @position = @position + 2;
            END;
            ELSE IF @next IN ('I', 'E', 'Y')
            BEGIN
                -- Italian vs English
                IF  @next = 'I'
                AND @following IN ('O', 'E', 'A')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'X';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'K';

                -- 'Mac Caffrey', 'Mac Gregor'
                IF  @next = ' '
                AND @following IN ('C', 'Q', 'G')
                BEGIN
                    SET @position = @position + 3;
                END;
                ELSE
                BEGIN
                    IF @next IN ('C', 'K', 'Q')
                    -- this logic is purposely commented out to match the output of the 
                    --  original function that was in use
                    --AND substring(@string, @position + 1, 2) NOT IN ('CE', 'CI')
                    BEGIN
                        SET @position = @position + 2;
                    END;
                    ELSE
                    BEGIN
                        SET @position = @position + 1;
                    END;
                END;
            END;
        END;


        -- 'D' transforms to 'J' if followed by 'GE', 'GY', or 'GI'
        -- otherwise, 'D' transforms to 'T'
        -- drop next character if it's 'D' or 'T'
        ELSE IF @current = 'D'
        BEGIN
            IF @next = 'G'
            BEGIN
                IF @following IN ('I', 'E', 'Y')
                BEGIN
                    -- 'edge'
                    SET @metaphone_1 = @metaphone_1 + 'J';
                    SET @metaphone_2 = @metaphone_2 + 'J';
                    SET @position = @position + 3;
                END;
                ELSE
                BEGIN
                    -- 'Edgar'
                    SET @metaphone_1 = @metaphone_1 + 'TK';
                    SET @metaphone_2 = @metaphone_2 + 'TK';
                    SET @position = @position + 2;
                END;
            END;
            ELSE IF @next IN ('D', 'T')
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'T';
                SET @metaphone_2 = @metaphone_2 + 'T';
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'T';
                SET @metaphone_2 = @metaphone_2 + 'T';
                SET @position = @position + 1;
            END;
        END;


        -- 'F' is kept
        -- drop next character if it's an 'F'
        ELSE IF @current = 'F'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'F';
            SET @metaphone_2 = @metaphone_2 + 'F';

            IF @next = 'F'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'G' can be transformed into 'K', 'J', 'F', 'KN', 'N', 'KL', 'L'
        -- check section comments for transformation rules
        ELSE IF @current = 'G'
        BEGIN
            IF @next = 'H'
            BEGIN
                IF  @position > 1
                AND @previous NOT IN ('A', 'E', 'I', 'O', 'U', 'Y')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'K';
                    SET @position = @position + 2;
                END;
                -- 'Ghislane', Ghiradelli
                ELSE IF @position = 1
                BEGIN
                    IF @following = 'I'
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'J';
                        SET @metaphone_2 = @metaphone_2 + 'J';
                    END;
                    ELSE
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'K';
                        SET @metaphone_2 = @metaphone_2 + 'K';
                    END;

                    SET @position = @position + 2;
                END;
                -- Parker's rule (with some further refinements) 
                -- 'Hugh'
                ELSE IF (   (   @position > 2
                            AND substring(@string, @position - 2, 1) IN ('B', 'H', 'D')
                            )
                            -- 'bough'
                        OR  (   @position > 3
                            AND substring(@string, @position - 3, 1) IN ('B', 'H', 'D')
                            )
                            -- 'Broughton'
                        OR  (   @position > 4
                            AND substring(@string, @position - 4, 1) IN ('B', 'H')
                            )
                        )
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    -- e.g., 'laugh', 'McLaughlin', 'cough', 'gough', 'rough', 'tough'
                    IF  (    @position > 3
                        AND @previous = 'U'
                        AND substring(@string, @position - 3, 1) IN ('C', 'G', 'L', 'R', 'T')
                        )
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'F';
                        SET @metaphone_2 = @metaphone_2 + 'F';
                    END;
                    ELSE
                    BEGIN
                        IF  (   @position > 1
                            AND @previous <> 'I'
                            )
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'K';
                            SET @metaphone_2 = @metaphone_2 + 'K';
                        END;
                    END;

                    SET @position = @position + 2;
                END;
            END; -- end 'GH'
            ELSE IF @next = 'N'
            BEGIN
                IF  (   @position = 2
                    AND @previous IN ('A', 'E', 'I', 'O', 'U', 'Y')
                    AND @is_slavo_germanic = 0
                    )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'KN';
                    SET @metaphone_2 = @metaphone_2 + 'N';
                END;
                ELSE
                BEGIN
                    -- not 'Cagney'
                    IF  (   substring(@string, @position + 2, 2) <> 'EY'
                        AND @next <> 'Y'
                        AND @is_slavo_germanic = 0
                        )
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'N';
                        SET @metaphone_2 = @metaphone_2 + 'KN';
                    END;
                    ELSE
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'KN';
                        SET @metaphone_2 = @metaphone_2 + 'KN';
                    END;
                END;

                SET @position = @position + 2;
            END; -- end 'GN'
            -- 'Tagliaro'
            ELSE IF (   substring(@string, @position + 1, 2) = 'LI'
                    AND @is_slavo_germanic = 0
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'KL';
                SET @metaphone_2 = @metaphone_2 + 'L';
                SET @position = @position + 2;
            END;
            -- ges-, gep-, gel-, gie- at beginning
            ELSE IF (   @position = 1
                    AND (   @next = 'Y'
                        OR  substring(@string, @position + 1, 2) IN ('ES', 'EP', 'EB', 'EL', 'EY', 'IB', 'IL', 'IN', 'IE', 'EI', 'ER')
                        )
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'J';
                SET @position = @position + 2;
            END;
            -- -ger-,  -gy-
            ELSE IF (   (   substring(@string, @position + 1, 2) = 'ER'
                        OR  @next = 'Y'
                        )
                    AND substring(@string, 1, 6) NOT IN ('DANGER', 'RANGER', 'MANGER')
                    AND substring(@string, @position - 1, 3) NOT IN ('RGY', 'OGY')
                    AND @previous NOT IN ('E', 'I')
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'J';
                SET @position = @position + 2;
            END;
            -- Italian; ex. 'Biaggi'
            ELSE IF @next IN ('E', 'I', 'Y')
                 OR substring(@string, @position - 1, 4) IN ('AGGI', 'OGGI')
            BEGIN
                -- obvious Germanic
                IF  (   (   substring(@string, 1, 4) IN ('VAN ', 'VON ')
                        OR  substring(@string, 1, 3) IN ('SCH')
                        )
                    OR  substring(@string, @position + 1, 2) = 'ET'
                    )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'K';
                    SET @metaphone_2 = @metaphone_2 + 'K';
                END;
                ELSE
                BEGIN
                    -- always soft if French ending
                    IF substring(@string, @position + 1, 4) = 'IER '
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'J';
                        SET @metaphone_2 = @metaphone_2 + 'J';
                    END;
                    ELSE
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'J';
                        SET @metaphone_2 = @metaphone_2 + 'K';
                    END;
                END;

                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                IF @next = 'G'
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;

                SET @metaphone_1 = @metaphone_1 + 'K';
                SET @metaphone_2 = @metaphone_2 + 'K';
            END;
        END;


        -- keep 'H' if it's the first character and before a vowel
        --  or between two vowels
        ELSE IF @current = 'H'
        BEGIN
            IF  (   @position = 1
                AND @next IN ('A', 'E', 'I', 'O', 'U', 'Y')
                )
            OR  (   @previous IN ('A', 'E', 'I', 'O', 'U', 'Y')
                AND @next IN ('A', 'E', 'I', 'O', 'U', 'Y')
                )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'H';
                SET @metaphone_2 = @metaphone_2 + 'H';
                SET @position = @position + 2;
            END;
            ELSE --also takes care of 'HH'
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'J' can be transformed to 'H' (mostly for Spanish words) or 'J'
        ELSE IF @current = 'J'
        BEGIN
            -- obvious Spanish, 'Jose', 'San Jacinto'
            IF  substring(@string, @position, 4) = 'JOSE'
            OR  substring(@string, 1, 4) = 'SAN '
            BEGIN
                IF  (   (   @position = 1
                        AND substring(@string, @position + 4, 1) = ' '
                        )
                    OR  substring(@string, 1, 4) = 'SAN '
                    )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'H';
                    SET @metaphone_2 = @metaphone_2 + 'H';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'J';
                    SET @metaphone_2 = @metaphone_2 + 'H';
                END;

                SET @position = @position + 1;
            END;
            -- Yankelovich / Jankelowicz
            ELSE IF  @position = 1
                 AND substring(@string, 1, 4) <> 'JOSE'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'J';
                SET @metaphone_2 = @metaphone_2 + 'A';

                IF @next = 'J'
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
            ELSE
            BEGIN
                -- Spanish pronunciation, 'bajador'
                IF  @previous IN ('A', 'E', 'I', 'O', 'U', 'Y')
                AND @next IN ('A', 'O')
                AND @is_slavo_germanic = 0
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'J';
                    SET @metaphone_2 = @metaphone_2 + 'H';
                END;
                ELSE
                BEGIN
                    IF @position = @len
                    BEGIN
                        SET @metaphone_1 = @metaphone_1 + 'J';
                        SET @metaphone_2 = @metaphone_2 + '';
                    END;
                    ELSE
                    BEGIN
                        -- keep if not between these letters
                        IF  @previous NOT IN ('S', 'K', 'L')
                        AND @next NOT IN ('L', 'T', 'K', 'S', 'N', 'M', 'B', 'Z')
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'J';
                            SET @metaphone_2 = @metaphone_2 + 'J';
                        END;
                    END;
                END;

                IF @next = 'J'
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
        END;


        -- keep 'K'
        -- drop next character if it's 'K'
        ELSE IF @current = 'K'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'K';
            SET @metaphone_2 = @metaphone_2 + 'K';

            IF @next = 'K'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- keep 'L'
        -- drop next character if it's 'L', no 'L' in alternate metaphone if word is Spanish
        ELSE IF @current = 'L'
        BEGIN
            IF @next = 'L'
            BEGIN
                -- Spanish; 'cabrillo', 'gallegos'
                IF  (   (   @position = (@len - 3)
                        AND substring(@string, @position - 1, 4) IN ('ILLO', 'ILLA', 'ALLE')
                        )
                    OR  (   (   substring(@string, @len - 1, 2) IN ('AS', 'OS')
                            OR  substring(@string, @len, 1) IN ('A', 'O')
                            )
                        AND substring(@string, @position - 1, 4) = 'ALLE'
                        )
                    )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'L';
                    SET @metaphone_2 = @metaphone_2 + '';
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'L';
                    SET @metaphone_2 = @metaphone_2 + 'L';
                    SET @position = @position + 2;
                END;
            END;
            ELSE
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'L';
                SET @metaphone_2 = @metaphone_2 + 'L';
                SET @position = @position + 1;
            END;
        END;


        -- keep 'M'
        -- drop next character if it's 'B' or 'M'
        ELSE IF @current = 'M'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'M';
            SET @metaphone_2 = @metaphone_2 + 'M';

            IF  (   substring(@string, @position - 1, 3) = 'UMB'
                AND (   @position + 1 = @len
                    OR  substring(@string, @position + 2, 2) = 'ER'
                    )
                )
            OR  @next = 'M'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- keep 'N'
        -- drop next character if it's 'N'
        ELSE IF @current = 'N'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'N';
            SET @metaphone_2 = @metaphone_2 + 'N';

            IF @next = 'N'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'P' tranforms to 'F' if 'PH' or 'PF' at start of word
        -- else keep 'P'
        ELSE IF @current = 'P'
        BEGIN
            IF  @next = 'H'
                -- 'Pfeiffer', 'Pfizer'
            OR  (   @position = 1
                AND @next = 'F'
                AND @following IN ('A', 'E', 'I', 'O', 'U', 'Y')
                )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'F';
                SET @metaphone_2 = @metaphone_2 + 'F';
                SET @position = @position + 2;
            END;
            -- 'Campbell', 'raspberry'
            ELSE
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'P';
                SET @metaphone_2 = @metaphone_2 + 'P';

                IF @next IN ('P', 'B')
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
        END;


        -- 'Q' tranforms to 'K'
        -- drop next character if it's 'Q'
        ELSE IF @current = 'Q'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'K';
            SET @metaphone_2 = @metaphone_2 + 'K';

            IF @next = 'Q'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- keep 'R' unless it comes at the end of a French word
        -- drop next character if it's 'R'
        ELSE IF @current = 'R'
        BEGIN
            -- French 'rogier', exclude 'hochmeier'
            IF  @position = @len
            AND @is_slavo_germanic = 0
            AND substring(@string, @position - 2, 2) = 'IE'
            AND substring(@string, @position - 4, 2) NOT IN ('ME', 'MA')
            BEGIN
                SET @metaphone_1 = @metaphone_1 + '';
                SET @metaphone_2 = @metaphone_2 + 'R';
            END;
            ELSE
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'R';
                SET @metaphone_2 = @metaphone_2 + 'R';
            END;

            IF @next = 'R'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'S' transforms to 'S', 'X' or 'SK'
        -- drop next character if it's 'S' or 'Z'
        ELSE IF @current = 'S'
        BEGIN
            -- special cases 'island', 'isle', 'Carlisle', 'Carlysle'; silent 'S'
            IF substring(@string, @position - 1, 3) IN ('ISL', 'YSL')
            BEGIN
                SET @position = @position + 1;
            END;
            -- special case 'sugar-'
            ELSE IF (   @position = 1
                    AND substring(@string, @position, 5) = 'SUGAR'
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'X';
                SET @metaphone_2 = @metaphone_2 + 'S';
                SET @position = @position + 1;
            END;
            ELSE IF @next = 'H'
            BEGIN
                -- Germanic
                IF substring(@string, @position + 1, 4) IN ('HEIM', 'HOEK', 'HOLM', 'HOLZ')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'X';
                    SET @metaphone_2 = @metaphone_2 + 'X';
                END;

                SET @position = @position + 2;
            END;
            -- Italian & Armenian
            ELSE IF substring(@string, @position, 3) IN ('SIO', 'SIA')
                 OR substring(@string, @position, 4) = 'SIAN'
            BEGIN
                IF @is_slavo_germanic = 0
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'X';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;

                SET @position = @position + 3;
            END;
            -- German & Anglicisations, e.g. 'smith' matches 'schmidt', 'snider' matches 'schneider'
            --  also, -sz- in Slavic language although in Hungarian it is pronounced 's'
            ELSE IF (   (   @position = 1
                        AND @next IN ('M', 'N', 'L', 'W')
                        )
                    OR  @next = 'Z'
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'S';
                SET @metaphone_2 = @metaphone_2 + 'X';

                IF @next = 'Z'
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
            ELSE IF @next = 'C'
            BEGIN
                -- Schlesinger's rule
                IF @following = 'H'
                BEGIN
                    -- Dutch origin; 'school', 'schooner'
                    IF substring(@string, @position + 3, 2) IN ('OO', 'ER', 'EN', 'UY', 'ED', 'EM')
                    BEGIN
                        -- 'Schermerhorn', 'Schenker'
                        IF substring(@string, @position + 3, 2) IN ('ER', 'EN')
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'X';
                            SET @metaphone_2 = @metaphone_2 + 'SK';
                        END;
                        ELSE
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'SK';
                            SET @metaphone_2 = @metaphone_2 + 'SK';
                        END;

                        SET @position = @position + 3;
                    END;
                    ELSE
                    BEGIN
                        IF  @position = 1
                        AND @following NOT IN ('A', 'E', 'I', 'O', 'U', 'Y')
                        AND @following <> 'W'
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'X';
                            SET @metaphone_2 = @metaphone_2 + 'S';
                        END;
                        ELSE
                        BEGIN
                            SET @metaphone_1 = @metaphone_1 + 'X';
                            SET @metaphone_2 = @metaphone_2 + 'X';
                        END;

                        SET @position = @position + 3;
                    END;
                END;
                ELSE IF @following IN ('I', 'E', 'Y')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                    SET @position = @position + 3;
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'SK';
                    SET @metaphone_2 = @metaphone_2 + 'SK';
                    SET @position = @position + 3;
                END;
            END; -- end 'SC'
            ELSE
            BEGIN
                -- French; 'resnais', 'artois'
                IF  @position = @len
                AND substring(@string, @position - 2, 2) IN ('AI', 'OI')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + '';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;

                IF @next IN ('S', 'Z')
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
        END;


        -- 'T' transforms to 'T', 'X' or '0'
        -- drop next character if it's 'T' or 'D'
        ELSE IF @current = 'T'
        BEGIN
            IF  (   substring(@string, @position, 3) IN ('TIA', 'TCH')
                OR  substring(@string, @position, 4) = 'TION'
                )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'X';
                SET @metaphone_2 = @metaphone_2 + 'X';
                SET @position = @position + 3;
            END;
            ELSE IF (   substring(@string, @position, 2) = 'TH'
                    OR  substring(@string, @position, 3) = 'TTH'
                    )
            BEGIN
                -- 'Thomas', 'Thames' or Germanic
                IF  (   substring(@string, @position + 2, 2) IN ('OM', 'AM')
                    OR  substring(@string, 1, 4) IN ('VAN ', 'VON ')
                    OR  substring(@string, 1, 3) = 'SCH'
                    )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'T';
                    SET @metaphone_2 = @metaphone_2 + 'T';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + '0';
                    SET @metaphone_2 = @metaphone_2 + 'T';
                END;

                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                IF @next IN ('T', 'D')
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;

                SET @metaphone_1 = @metaphone_1 + 'T';
                SET @metaphone_2 = @metaphone_2 + 'T';
            END;
        END;


        -- 'V' transforms to 'F'
        -- drop next character if it's 'V'
        ELSE IF @current = 'V'
        BEGIN
            SET @metaphone_1 = @metaphone_1 + 'F';
            SET @metaphone_2 = @metaphone_2 + 'F';

            IF @next = 'V'
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'W' transforms to     
        ELSE IF @current = 'W'
        BEGIN
            -- 'WR'
            IF @next = 'R'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'R';
                SET @metaphone_2 = @metaphone_2 + 'R';
                SET @position = @position + 2;
            END;
            ELSE IF (   @position = 1
                    AND (   @next IN ('A', 'E', 'I', 'O', 'U', 'Y')
                        OR  @next = 'H'
                        )
                    )
            BEGIN
                -- Wasserman should match Vasserman
                IF @next IN ('A', 'E', 'I', 'O', 'U', 'Y')
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'A';
                    SET @metaphone_2 = @metaphone_2 + 'F';
                END;
                ELSE
                BEGIN
                    -- need Uomo to match Womo
                    SET @metaphone_1 = @metaphone_1 + 'A';
                    SET @metaphone_2 = @metaphone_2 + 'A';
                END;

                SET @position = @position + 1;
            END;
            -- Arnow should match Arnoff
            ELSE IF (   (   @position = @len
                        AND @previous IN ('A', 'E', 'I', 'O', 'U', 'Y')
                        )
                    OR  substring(@string, @position - 1, 5) IN ('EWSKI', 'EWSKY', 'OWSKI', 'OWSKY')
                    OR  substring(@string, 1, 3) = 'SCH'
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + '';
                SET @metaphone_2 = @metaphone_2 + 'F';
                SET @position = @position + 1;
            END;
            -- Polish; 'Filipowicz'
            ELSE IF substring(@string, @position, 4) IN ('WICZ', 'WITZ')
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'TS';
                SET @metaphone_2 = @metaphone_2 + 'FX';
                SET @position = @position + 4;
            END;
            ELSE -- skip it
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'X' transforms to 'KS'
        -- drop if next character if it's 'C' or 'X'
        -- or if it's at the end of a French word
        ELSE IF @current = 'X'
        BEGIN
            -- French; 'breaux'
            IF NOT  (   @position = @len
                    AND (   substring(@string, @position - 3, 3) IN ('IAU', 'EAU')
                        OR  substring(@string, @position - 2, 2) IN ('AU', 'OU')
                        )
                    )
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'KS';
                SET @metaphone_2 = @metaphone_2 + 'KS';
            END;
            IF @next IN ('C', 'X')
            BEGIN
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                SET @position = @position + 1;
            END;
        END;


        -- 'Z' transforms to 'S'
        -- exceptions for Chinese and Slavo Germanic words
        -- drop next character if it's 'Z'
        ELSE IF @current = 'Z'
        BEGIN
            --Chinese Pinyin; ex. 'Zhao'
            IF @next = 'H'
            BEGIN
                SET @metaphone_1 = @metaphone_1 + 'J';
                SET @metaphone_2 = @metaphone_2 + 'J';
                SET @position = @position + 2;
            END;
            ELSE
            BEGIN
                IF  (   @next IN ('O', 'I', 'A')
                    OR  (   @is_slavo_germanic = 1
                        AND (   @position > 1
                            AND @previous <> 'T'
                            )
                        )
                   )
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'TS';
                END;
                ELSE
                BEGIN
                    SET @metaphone_1 = @metaphone_1 + 'S';
                    SET @metaphone_2 = @metaphone_2 + 'S';
                END;
                IF @next = 'Z'
                BEGIN
                    SET @position = @position + 2;
                END;
                ELSE
                BEGIN
                    SET @position = @position + 1;
                END;
            END;
        END;

        -- if letter is not in above logic, drop it
        ELSE
        BEGIN
            SET @position = @position + 1;
        END;

    END;


    -- only give back 4 char metaphone
    SET @metaphone_1 = left(@metaphone_1, 4);
    SET @metaphone_2 = left(@metaphone_2, 4);
    SET @metaphone_value = @metaphone_1;


    -- if return type is 2, return alternate metaphone
    -- return empty string if secondary metaphone value os the same as the primary
    IF @return_type = 2
    BEGIN
        IF @metaphone_2 = @metaphone_1
        BEGIN
            SET @metaphone_value = '';
        END;
        ELSE
        BEGIN
            SET @metaphone_value = @metaphone_2;
        END;
    END;


    RETURN @metaphone_value;
END;

GO
