/* ================================================================================================
Purpose:
    Example of how to delete a large set of data in small batches (to prevent space issues with TempDB).
    This leverages the clustered key.

History:
    Taken from http://michaeljswart.com/2014/09/take-care-when-scripting-batches/
================================================================================================ */

DECLARE @largest_key_processed int = -1,
        @next_batch_max        int,
        @counter               int = 1;


-- loop through the records to be deleted until there are no more records that match the criteria   
WHILE ( @counter > 0 )
BEGIN

    SELECT      TOP ( 10000 )
                @next_batch_max = sales_key
    FROM        dbo.fact_sales
    WHERE       sales_key > @largest_key_processed
    AND         customer_key = 19036
    ORDER BY    sales_key ASC;

    DELETE  
    FROM    dbo.fact_sales
    WHERE   customer_key = 19036
    AND     sales_key > @largest_key_processed
    AND     sales_key <= @next_batch_max;

    SET @counter = @@rowcount;
    SET @largest_key_processed = @next_batch_max;

END;
