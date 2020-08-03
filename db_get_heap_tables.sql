/*
-- =================================================================================================
Purpose:
    Returns tables without a clustered index (aka "Heap").

History:
    2018-05-30  Tom Hogan
                - Created, based on a script by Phil Factor.
-- =================================================================================================
*/

SELECT  object_schema_name(t.[object_id]) + '.' + object_name(t.[object_id])    AS heaps
FROM    sys.indexes AS i
JOIN    sys.tables  AS t    ON  t.[object_id] = i.[object_id]
WHERE   i.[type] = 0
;
