/* ================================================================================================
Purpose:
    Creates a table to hold sequential number values.

History:
    Based on a script by Jeff Moden.
================================================================================================ */
SET NOCOUNT ON;


/*
    create table
*/
DROP TABLE IF EXISTS dbo.tally;

CREATE TABLE dbo.tally
(
    n int NOT NULL,
    CONSTRAINT tally_pk
        PRIMARY KEY CLUSTERED ( n )
);
GO


/*
    load with initial data
*/
INSERT INTO dbo.tally
(
            n
)
SELECT      TOP ( 100000 )
            row_number() OVER ( ORDER BY t1.number ) AS n
FROM        master.dbo.spt_values AS t1
CROSS JOIN  master.dbo.spt_values AS t2;

GO
