/* ================================================================================================
Purpose:
    List SQL Agent jobs and their associated replication publications on the Distributor.

History:
    2011-12-07  Tom Hogan           Created.
================================================================================================ */
USE distribution;   /* change if your distribution database is named differently than the default */


SELECT      a.publication,
            a.publisher_db,
            a.name,
            'Distribution'  AS agent_type
FROM        dbo.MSDistribution_agents   AS a
WHERE       a.subscriber_id > 0
UNION ALL
SELECT      a.publication,
            a.publisher_db,
            a.name,
            'Snapshot'      AS agent_type
FROM        dbo.MSSnapshot_agents   AS a
ORDER BY    publisher_db,
            publication,
            name;
