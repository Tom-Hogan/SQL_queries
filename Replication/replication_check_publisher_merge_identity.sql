/* ================================================================================================
Purpose:
    Returns identity ranges for merge replication on the Publisher.

Notes:
    Each query needs to be run against the appropriate server and database.

History:
    2011-12-07  Tom Hogan           Created.
================================================================================================ */
RAISERROR(N'Remember! Each query needs to be run separately.', 20, 1) WITH LOG;
GO


/* publisher */
SELECT      a.name,
            i.*
FROM        dbo.MSmerge_identity_range  AS i
JOIN        dbo.sysmergearticles        AS a    ON  a.artid = i.artid
ORDER BY    a.name;


/* distribution */
SELECT      *
FROM        dbo.MSmerge_identity_range_allocations
ORDER BY    time_of_allocation DESC;
