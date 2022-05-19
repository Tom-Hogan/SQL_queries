/* ================================================================================================
Purpose:
    Examples of creating a tally table and some of the things you can do with it.
 
History:
    2010-07-08  Tom Hogan           Created.  Based on work by several authors.
================================================================================================ */

/*
    create Tally table
    (ideally this should be a permanent table)
*/
/* create and populate the Tally table on the fly */
SELECT      TOP ( 10000 )
            identity(int, 1, 1) AS n
INTO        #tally
FROM        master.dbo.spt_values AS t1
CROSS JOIN  master.dbo.spt_values AS t2;

/* add a Primary Key to maximize performance */
ALTER TABLE #tally
ADD CONSTRAINT pk_#tally
    PRIMARY KEY CLUSTERED ( n )
    WITH FILLFACTOR = 100;


/*
    example of using the Tally table to parse a string
*/
DECLARE @parameter varchar(8000),
        @delimiter varchar(10);

-- table variable to hold example data
DECLARE @elements_table table
(
    number       int           IDENTITY(1, 1) NOT NULL, /* order it appears in original string */
    string_value varchar(8000) NOT NULL                 /* the string value of the element */
);

SET @parameter = 'Element01;Element02;Element03;Element04;Element05';
SET @delimiter = ';';
SET @parameter = @delimiter + @parameter + @delimiter;

/* load table variable with parsed string data */
INSERT INTO @elements_table
(
        string_value
)
SELECT  substring(@parameter, n + 1, charindex(@delimiter, @parameter, n + 1) - n - 1)
FROM    #tally
WHERE   n < len(@parameter)
AND     substring(@parameter, n, 1) = @delimiter;


SELECT  string_value
FROM    @elements_table;
